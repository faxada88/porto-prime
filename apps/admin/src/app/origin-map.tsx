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
  const [mapOpen, setMapOpen] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [loading, setLoading] = useState(true);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState("");
  const [latitude, setLatitude] = useState(lat?.toString() ?? "");
  const [longitude, setLongitude] = useState(lng?.toString() ?? "");
  const [locating, setLocating] = useState(false);

  useEffect(() => {
    if (!mapOpen) { setLoading(false); setReady(false); return; }
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
  }, [attempt, mapOpen]);

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
    onChange(Number(a.toFixed(7)), Number(b.toFixed(7))); setError("");
  };
  const usePosition = () => {
    if (!navigator.geolocation) { setError("Este navegador não disponibiliza localização. Informe as coordenadas ou selecione o ponto no mapa."); return; }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(p => { setLocating(false); if(p.coords.accuracy>50){setError("A localização do navegador está imprecisa. Informe as coordenadas exatas ou selecione a entrada no mapa.");return;} onChange(Number(p.coords.latitude.toFixed(7)), Number(p.coords.longitude.toFixed(7))); setError(""); }, () => { setLocating(false); setError("Não conseguimos acessar sua localização. Autorize no navegador ou selecione o ponto da loja manualmente."); }, { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
  };
  return <div className="originMapSection">
    <button className="originUsePosition" type="button" disabled={locating} onClick={usePosition}><LocateFixed size={20} /> {locating ? "Obtendo localização…" : "Estou na loja: usar minha localização"}</button>
    <p className="originPositionHelp">Use esta opção somente se você estiver fisicamente na distribuidora. Autorize a localização no navegador.</p>
    <div className="originMapCoordinates"><h4>Ou informe as coordenadas da entrada</h4><p>Latitude e longitude identificam o ponto exato. Não é necessário buscar pelo nome da rua.</p><div><label htmlFor="origin-latitude"><span>Latitude</span><input id="origin-latitude" inputMode="decimal" autoComplete="off" value={latitude} onChange={e => setLatitude(e.target.value)} placeholder="Ex.: -16.4490000" /></label><label htmlFor="origin-longitude"><span>Longitude</span><input id="origin-longitude" inputMode="decimal" autoComplete="off" value={longitude} onChange={e => setLongitude(e.target.value)} placeholder="Ex.: -39.0640000" /></label><button type="button" onClick={confirmCoordinates}><Check size={16} /> Usar este ponto</button></div></div>
    {lat!==null&&lng!==null&&<div className="originSelectedPoint" role="status"><MapPin size={19}/><span><strong>Ponto definido</strong><small>{lat.toFixed(7)}, {lng.toFixed(7)}</small></span></div>}
    {error && <div className="originMapError" role="alert"><span>{error}</span>{mapOpen&&<button type="button" onClick={() => setAttempt(a => a + 1)}><RefreshCw size={16} /> Recarregar mapa</button>}</div>}
    <button className="originToggleMap" type="button" aria-expanded={mapOpen} onClick={()=>setMapOpen(v=>!v)}><MapPin size={18}/>{mapOpen?"Fechar mapa":"Prefiro selecionar no mapa"}</button>
    {mapOpen&&<><div className="primeOriginMap" ref={container} role="region" aria-label="Mapa interativo. Clique na entrada da distribuidora ou arraste o marcador." />
    {loading && <div className="originMapMessage" role="status"><RefreshCw size={18} /> Carregando mapa da região…</div>}
    <div className="originMapActions"><p>Clique na entrada da loja. Arraste o marcador para ajustar.</p><button type="button" disabled={!ready} onClick={() => { const p = map.current?.getCenter(); if(p)onChange(p.lat,p.lng); }}><Check size={16} /> Usar centro do mapa</button></div></>}
  </div>;
}
