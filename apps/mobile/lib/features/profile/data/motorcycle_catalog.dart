class MotorcycleCatalog {
  static const brands = <String, List<String>>{
    'Honda': [
      'CG 160 Start',
      'CG 160 Fan',
      'CG 160 Titan',
      'Biz 125',
      'Pop 110i ES',
      'NXR 160 Bros',
      'PCX 160',
    ],
    'Yamaha': [
      'Factor 150',
      'Fazer FZ15',
      'Fazer FZ25',
      'Crosser 150',
      'Fluo ABS',
      'NMAX 160',
    ],
    'Shineray': ['Jet 125 SS', 'Worker 125', 'SHI 175', 'Urban 150'],
    'Haojue': ['DK 160', 'DR 160', 'NEX 115', 'Master Ride 150'],
    'Suzuki': ['Burgman 125i', 'GSX-S150'],
  };

  static List<String> get brandOptions => [...brands.keys, 'Outra marca'];

  static List<String> modelsFor(String brand) => [
    ...?brands[brand],
    'Outro modelo',
  ];
}
