import test from 'node:test';
import assert from 'node:assert/strict';
import { isKnownPostgres16Image } from './repair-local-db-port.mjs';

const id = 'sha256:' + 'a'.repeat(64);
const otherId = 'sha256:' + 'b'.repeat(64);
const digest = 'postgres@sha256:' + 'c'.repeat(64);
const container = (reference = 'postgres:16') => ({ Image: id, Config: { Image: reference } });
const image = (overrides = {}) => ({
  Id: id, Config: { Env: ['PG_MAJOR=16'] },
  RepoTags: ['postgres:16'], RepoDigests: [digest], ...overrides,
});

test('recognizes the original tagged PostgreSQL 16 image', () => {
  assert.equal(isKnownPostgres16Image(container(), image()), true);
});
test('recognizes the exact image ID used by a previous successful port repair', () => {
  assert.equal(isKnownPostgres16Image(container(id), image()), true);
  assert.equal(isKnownPostgres16Image(container(id.slice(7)), image()), true);
});
test('recognizes an existing official 16 image after its mutable tag moves', () => {
  assert.equal(isKnownPostgres16Image(container(id), image({ RepoTags: [] })), true);
});
test('recognizes the canonical Docker Hub reference', () => {
  assert.equal(isKnownPostgres16Image(container('docker.io/library/postgres:16'),
    image({ RepoTags: ['docker.io/library/postgres:16'], RepoDigests: [] })), true);
});
test('does not accept PostgreSQL 17 even if a tag or reference says 16', () => {
  assert.equal(isKnownPostgres16Image(container(id), image({ Config: { Env: ['PG_MAJOR=17'] } })), false);
});
test('does not accept an unrelated custom image based only on PG_MAJOR', () => {
  assert.equal(isKnownPostgres16Image(container(id),
    image({ RepoTags: ['custom/database:16'], RepoDigests: [] })), false);
});
test('does not accept an image inspection for another image ID', () => {
  assert.equal(isKnownPostgres16Image(container(id), image({ Id: otherId })), false);
});
test('does not accept an unexpected container image reference', () => {
  assert.equal(isKnownPostgres16Image(container('custom/database:latest'), image()), false);
});
test('does not accept missing or ambiguous version metadata', () => {
  assert.equal(isKnownPostgres16Image(container(id), image({ Config: { Env: [] } })), false);
  assert.equal(isKnownPostgres16Image(container(id), image({ Config: {} })), false);
});
test('does not accept missing or malformed image IDs', () => {
  assert.equal(isKnownPostgres16Image({}, image()), false);
  assert.equal(isKnownPostgres16Image({ Image: 'unknown', Config: { Image: 'unknown' } }, { Id: 'unknown' }), false);
});
