import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const name = 'porto-prime-github-db';
const volume = 'porto-prime-github-pgdata';
const destination = '/var/lib/postgresql/data';
const envPath = join(root, 'apps', 'api', '.env');
const docker = (...args) => execFileSync('docker', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], timeout: 60000 }).trim();
const inspect = (target) => JSON.parse(docker('inspect', target))[0];
const pause = (ms) => new Promise((done) => setTimeout(done, ms));

function publishedPort(container) {
  const bindings = container.NetworkSettings?.Ports?.['5432/tcp'] ?? [];
  const binding = bindings.find((item) => ['', '127.0.0.1', '0.0.0.0'].includes(item.HostIp));
  const port = Number(binding?.HostPort);
  return Number.isInteger(port) && port > 0 && port <= 65535 ? port : null;
}

function portResponds(port) {
  if (!port) return Promise.resolve(false);
  return new Promise((done) => {
    const socket = net.createConnection({ host: '127.0.0.1', port });
    const finish = (ok) => { socket.destroy(); done(ok); };
    socket.once('connect', () => finish(true));
    socket.once('error', () => finish(false));
    socket.setTimeout(3000, () => finish(false));
  });
}


async function availablePort() {
  for (const port of [15432, 15433, 15434, 25432, 35432]) {
    const free = await new Promise((done) => {
      const server = net.createServer();
      server.once('error', () => done(false));
      server.listen({ host: '127.0.0.1', port, exclusive: true }, () => server.close(() => done(true)));
    });
    if (free) return port;
  }
  throw new Error('Nenhuma porta alternativa disponivel. O banco nao foi modificado.');
}

export function updateDatabaseUrl(text, oldPort, newPort) {
  const pattern = /^([ \t]*(?:export[ \t]+)?DATABASE_URL[ \t]*=[ \t]*)([^\r\n]*)/gm;
  const matches = [...text.matchAll(pattern)];
  if (matches.length !== 1) throw new Error('Esperada uma unica DATABASE_URL em apps/api/.env. Nenhuma alteracao realizada.');
  const raw = matches[0][2].trim();
  const quote = raw[0] === '"' || raw[0] === "'" ? raw[0] : '';
  if (quote && raw.at(-1) !== quote) throw new Error('Formato da DATABASE_URL nao reconhecido.');
  const value = quote ? raw.slice(1, -1) : raw;
  let url;
  try { url = new URL(value); } catch { throw new Error('DATABASE_URL invalida. Nenhuma alteracao realizada.'); }
  if (!['postgres:', 'postgresql:'].includes(url.protocol) ||
      !['localhost', '127.0.0.1'].includes(url.hostname) ||
      (oldPort !== null && Number(url.port || 5432) !== Number(oldPort)) ||
      url.searchParams.has('host')) {
    throw new Error('DATABASE_URL nao aponta para a porta local deste container. Nenhuma alteracao realizada.');
  }
  url.hostname = '127.0.0.1';
  url.port = String(newPort);
  return text.replace(pattern, () => matches[0][1] + quote + url.toString() + quote);
}


// A port repair creates the replacement with the original image ID. Docker then
// records Config.Image as sha256:..., rather than the original postgres:16 tag.
// Resolve that exact ID and verify its version and PostgreSQL image provenance.
export function isKnownPostgres16Image(container, image) {
  const id = container?.Image;
  if (typeof id !== 'string' || !/^sha256:[a-f0-9]{64}$/i.test(id) || image?.Id !== id) return false;
  const reference = container.Config?.Image;
  if (!['postgres:16', 'docker.io/library/postgres:16', id, id.slice(7)].includes(reference)) return false;
  if (!(image.Config?.Env ?? []).includes('PG_MAJOR=16')) return false;
  const tags = image.RepoTags ?? [];
  const knownTag = tags.some((tag) => ['postgres:16', 'docker.io/library/postgres:16'].includes(tag));
  const officialDigest = (image.RepoDigests ?? []).some((digest) =>
    /^(?:(?:docker\.io\/)?library\/)?postgres@sha256:[a-f0-9]{64}$/i.test(digest));
  return knownTag || officialDigest;
}

async function main() {
  if (!existsSync(envPath)) throw new Error('apps/api/.env nao encontrado.');
  const original = inspect(name);
  const mounts = original.Mounts ?? [];
  const image = JSON.parse(docker('image', 'inspect', original.Image))[0];
  if (!isKnownPostgres16Image(original, image)) {
    throw new Error('A imagem existente nao foi reconhecida como PostgreSQL 16 oficial. Nada foi alterado.');
  }
  if (mounts.length !== 1 || mounts[0].Type !== 'volume' ||
      mounts[0].Name !== volume || mounts[0].Destination !== destination) {
    throw new Error('O volume ou diretorio do banco e diferente do porto-prime-github-pgdata esperado. Nada foi alterado.');
  }
  const variables = original.Config.Env ?? [];
  const findVariable = (key, fallback) => variables.find((entry) => entry.startsWith(key + '='))?.slice(key.length + 1) || fallback;
  const user = findVariable('POSTGRES_USER', 'postgres');
  const database = findVariable('POSTGRES_DB', user);
  const activePort = publishedPort(original);
  if (original.State.Running && activePort && await portResponds(activePort)) {
    docker('exec', name, 'pg_isready', '-q', '-U', user, '-d', database);
    const previousEnv = readFileSync(envPath, 'utf8');
    const nextEnv = updateDatabaseUrl(previousEnv, null, activePort);
    if (readFileSync(envPath, 'utf8') !== previousEnv) throw new Error('O .env mudou durante a operacao. Repita com o arquivo fechado.');
    if (nextEnv !== previousEnv) writeFileSync(envPath, nextEnv, 'utf8');
    console.log('Banco pronto em 127.0.0.1:' + activePort + '. DATABASE_URL conferida e sincronizada.');
    console.log('Container, volume e credenciais preservados. Reinicie o Nest para carregar a conexao atualizada.');
    return;
  }
  // Docker may report Running after a failed host-port setup. Recreate only
  // this container if it has no working published endpoint, retaining PGDATA.
  if (JSON.stringify(original.Config.Cmd) !== JSON.stringify(['postgres']) ||
      !['bridge', 'default'].includes(original.HostConfig.NetworkMode)) {
    throw new Error('Este banco tem inicializacao ou rede personalizada. Nada foi alterado.');
  }
  const port = await availablePort();
  const previousEnv = readFileSync(envPath, 'utf8');
  const nextEnv = updateDatabaseUrl(previousEnv, null, port);
  // Reuse the exact image already installed; never download or upgrade Postgres.
  docker('volume', 'inspect', volume);
  // Refuse to initialize a fresh database if the known volume has lost its data.
  const version = docker('run', '--rm', '--network', 'none', '--read-only',
    '--mount', 'type=volume,source=' + volume + ',target=' + destination + ',readonly',
    '--entrypoint', 'cat', original.Image, destination + '/PG_VERSION');
  if (version !== '16') throw new Error('O volume nao contem um banco PostgreSQL 16 existente. Nada foi alterado.');
  if (findVariable('PGDATA', destination) !== destination) throw new Error('PGDATA personalizado. Nada foi alterado.');
  const activeContainers = docker('ps', '--filter', 'volume=' + volume, '--format', '{{.ID}}').split(/\r?\n/).filter(Boolean);
  if (activeContainers.some((id) => !original.Id?.startsWith(id))) {
    throw new Error('Outro container esta usando o volume. Nenhum banco foi parado ou recriado.');
  }

  const stamp = new Date().toISOString().replace(/[^0-9]/g, '');
  const backup = name + '-backup-' + stamp;
  const work = mkdtempSync(join(tmpdir(), 'porto-db-port-'));
  const envFile = join(work, 'postgres.env');
  let renamed = false, created = false, envChanged = false, restartChanged = false;
  const restart = original.HostConfig.RestartPolicy;
  const restartValue = restart.Name === 'on-failure' && restart.MaximumRetryCount > 0 ?
    'on-failure:' + restart.MaximumRetryCount : restart.Name || 'no';
  try {
    if (variables.some((entry) => /[\r\n]/.test(entry))) throw new Error('Variavel Docker com formato nao suportado.');
    writeFileSync(envFile, variables.join('\n') + '\n', { mode: 0o600 });
    // A stopped backup must never auto-start against the same live PGDATA.
    docker('update', '--restart=no', name);
    restartChanged = true;
    if (original.State.Running) {
      console.log('Reconfigurando a publicacao da porta do banco. Volume existente mantido.');
      docker('stop', '--time', '30', name);
      if (inspect(name).State.Running) throw new Error('O banco nao parou. Nenhum segundo PostgreSQL sera iniciado.');
    }
    docker('rename', name, backup);
    renamed = true;
    console.log('Container antigo preservado e parado: ' + backup);
    docker('create', '--name', name, '--restart', restartValue,
      '--publish', '127.0.0.1:' + port + ':5432',
      '--mount', 'type=volume,source=' + volume + ',target=' + destination,
      '--env-file', envFile, original.Image);
    created = true;
    docker('start', name);
    let ready = false;
    for (let attempt = 0; attempt < 45; attempt++) {
      try {
        docker('exec', name, 'pg_isready', '-q', '-U', user, '-d', database);
        if (await portResponds(port)) { ready = true; break; }
        await pause(1000);
      } catch {
        if (!inspect(name).State.Running) break;
        await pause(1000);
      }
    }
    if (!ready || !await portResponds(port)) throw new Error('O PostgreSQL nao ficou acessivel pela nova porta. A configuracao anterior sera restaurada.');
    // Avoid overwriting edits made while PostgreSQL was starting.
    if (readFileSync(envPath, 'utf8') !== previousEnv) throw new Error('O .env mudou durante a operacao. Repita com o arquivo fechado.');
    writeFileSync(envPath, nextEnv, 'utf8');
    envChanged = true;
    console.log('Banco pronto em 127.0.0.1:' + port + '. DATABASE_URL atualizada.');
    console.log('Dados e credenciais preservados. Reinicie somente o Nest com npm run start:dev em apps/api.');
  } catch (error) {
    if (envChanged) writeFileSync(envPath, previousEnv, 'utf8');
    if (created) {
      try { docker('stop', name); } catch {}
      // Only remove the new container created by this run; never remove volumes.
      try { docker('rm', name); } catch {}
    }
    if (renamed) {
      try { docker('rename', backup, name); docker('update', '--restart', restartValue, name); } catch {
        console.error('O container antigo continua preservado como: ' + backup + '. Nao inicie dois bancos com o mesmo volume.');
      }
    } else if (restartChanged) {
      try { docker('update', '--restart', restartValue, name); } catch {}
    }
    throw error;
  } finally { rmSync(work, { recursive: true, force: true }); }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    // Docker error objects can contain environment data; do not print their arguments.
    const safe = error?.stderr ? 'Comando Docker falhou. Dados preservados. Verifique Docker Desktop e a disponibilidade da porta.' : error.message;
    console.error(safe);
    process.exitCode = 1;
  });
}
