"use client";
import { useEffect, useRef, useState } from "react";
import type { Map as MapLibreMap, Marker } from "maplibre-gl";
import { Check, LocateFixed, MapPin, RefreshCw } from "lucide-react";

type Props = { lat: number | null; lng: number | null; onChange: (lat: number, lng: number) => void };
export default function OriginMap({ lat, lng, onChange }: Props) {
  const container = useRef<HTMLDivElement>(null);
  const map = useRef<MapLibreMap | null>(null);
  const marker = useRef<Marker | null>(null);
  const latest = useRef({ lat, lng, onChange });
  latest.current = { lat, lng, onChange };
  const [attempt, setAttempt] = useState(0);
  const [loading, setLoading] = useState(true);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState("");
  const [latitude, setLatitude] = useState(lat?.toString() ?? "");
  const [longitude, setLongitude] = useState(lng?.toString() ?? "");
  const [locating, setLocating] = useState(false);

  useEffect(() => {
    let disposed = false;
    let instance: MapLibreMap | null = null;
    let observer: ResizeObserver | null = null;
    setLoading(true); setReady(false); setError("");
    const timeout = window.setTimeout(() => {
      if (!disposed) { setLoading(false); setError("O mapa demorou para carregar. Tente novamente ou informe as coordenadas abaixo."); }
    }, 15000);
    import("maplibre-gl").then(({ Map, Marker, NavigationControl, GeolocateControl }) => {
      if (disposed || !container.current) return;
      instance = new Map({
        container: container.current,
        style: process.env.NEXT_PUBLIC_MAP_STYLE_URL || "https://tiles.openfreemap.org/styles/liberty",
        center: [latest.current.lng ?? -39.064, latest.current.lat ?? -16.449],
        zoom: 16, minZoom: 3, maxZoom: 20,
        attributionControl: { compact: false },
      });
      map.current = instance;
      instance.addControl(new NavigationControl({ showCompass: false }), "top-right");
      instance.addControl(new GeolocateControl({ positionOptions: { enableHighAccuracy: true }, trackUserLocation: false }), "top-right");
      const pin = new Marker({ color: "#0b5154", draggable: true });
      marker.current = pin;
      if (latest.current.lat !== null && latest.current.lng !== null) pin.setLngLat([latest.current.lng, latest.current.lat]).addTo(instance);
      pin.on("dragend", () => { const p = pin.getLngLat(); latest.current.onChange(p.lat, p.lng); });
      instance.on("click", e => { pin.setLngLat(e.lngLat).addTo(instance!); latest.current.onChange(e.lngLat.lat, e.lngLat.lng); });
      instance.on("load", () => { if (!disposed) { window.clearTimeout(timeout); setLoading(false); setReady(true); setError(""); } });
      instance.on("error", () => { if (!disposed) { setLoading(false); setError("Não foi possível carregar parte do mapa. Verifique a conexão, tente novamente ou use as coordenadas abaixo."); } });
      observer = new ResizeObserver(() => instance?.resize());
      observer.observe(container.current);
    }).catch(() => {
      if (!disposed) { window.clearTimeout(timeout); setLoading(false); setError("O mapa não está disponível neste navegador. Use as coordenadas abaixo ou tente novamente."); }
    });
    return () => { disposed = true; window.clearTimeout(timeout); observer?.disconnect(); marker.current?.remove(); marker.current = null; instance?.remove(); map.current = null; };
  }, [attempt]);

  useEffect(() => {
    setLatitude(lat?.toString() ?? ""); setLongitude(lng?.toString() ?? "");
    if (lat !== null && lng !== null && map.current && marker.current) {
      marker.current.setLngLat([lng, lat]).addTo(map.current);
      map.current.easeTo({ center: [lng, lat], duration: 250 });
    }
  }, [lat, lng]);

  const confirmCoordinates = () => {
    const a = Number(latitude.replace(",", ".")), b = Number(longitude.replace(",", "."));
    if (!latitude.trim() || !longitude.trim() || !Number.isFinite(a) || !Number.isFinite(b) || Math.abs(a) > 90 || Math.abs(b) > 180) { setError("Informe latitude entre −90 e 90 e longitude entre −180 e 180."); return; }
    onChange(a, b); setError("");
  };
  const usePosition = () => {
    if (!navigator.geolocation) { setError("Este navegador não disponibiliza localização. Informe as coordenadas ou selecione o ponto no mapa."); return; }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(p => { setLocating(false); onChange(p.coords.latitude, p.coords.longitude); }, () => { setLocating(false); setError("Não conseguimos acessar sua localização. Autorize no navegador ou selecione o ponto da loja manualmente."); }, { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
  };
  return <div className="originMapSection">
    <div className="primeOriginMap" ref={container} role="region" aria-label="Mapa interativo. Clique na entrada da distribuidora ou arraste o marcador." />
    {loading && <div className="originMapMessage" role="status"><RefreshCw size={18} /> Carregando mapa da região…</div>}
    {error && <div className="originMapError" role="alert"><span>{error}</span><button type="button" onClick={() => setAttempt(a => a + 1)}><RefreshCw size={16} /> Tentar novamente</button></div>}
    <div className="originMapActions"><p><MapPin size={18} /> Clique na entrada da loja. Arraste o marcador para ajustar.</p><button type="button" disabled={!ready} onClick={() => { const p = map.current?.getCenter(); if(p)onChange(p.lat,p.lng); }}><Check size={16} /> Selecionar centro do mapa</button><button type="button" disabled={locating} onClick={usePosition}><LocateFixed size={16} /> {locating ? "Localizando…" : "Estou na loja: usar minha posição"}</button></div>
    <details className="originMapCoordinates" open={!!error}><summary>Informar coordenadas da loja</summary><div><label>Latitude<input inputMode="decimal" value={latitude} onChange={e => setLatitude(e.target.value)} placeholder="Ex.: -16.449" /></label><label>Longitude<input inputMode="decimal" value={longitude} onChange={e => setLongitude(e.target.value)} placeholder="Ex.: -39.064" /></label><button type="button" onClick={confirmCoordinates}>Confirmar coordenadas</button></div></details>
  </div>;
}
