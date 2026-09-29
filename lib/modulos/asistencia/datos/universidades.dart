class Universidad {
  final String nombre;
  final String sigla;
  final String tipo; // "Pública", "Régimen especial" o "Privada"
  const Universidad(this.nombre, this.sigla, this.tipo);
}

const UNIVERSIDADES_LA_PAZ_EL_ALTO = <Universidad>[
  Universidad("Universidad Mayor de San Andrés", "UMSA", "Pública"),
  Universidad("Universidad Pública de El Alto", "UPEA", "Pública"),
  Universidad(
    "Universidad Indígena Boliviana Aymara \"Tupak Katari\"",
    "UNIBOL",
    "Pública",
  ),
  Universidad(
    "Universidad Católica Boliviana \"San Pablo\"",
    "UCB",
    "Régimen especial",
  ),
  Universidad("Escuela Militar de Ingeniería", "EMI", "Régimen especial"),
  Universidad(
    "Universidad Policial \"Mariscal Antonio José de Sucre\"",
    "UNIPOL",
    "Régimen especial",
  ),
  Universidad("Universidad Privada Boliviana", "UPB", "Privada"),
  Universidad("Universidad Privada del Valle", "UNIVALLE", "Privada"),
  Universidad("Universidad Privada Franz Tamayo", "UNIFRANZ", "Privada"),
  Universidad("Universidad Loyola", "ULOYOLA", "Privada"),
  Universidad("Universidad Salesiana de Bolivia", "USB", "Privada"),
  Universidad("Universidad Nuestra Señora de La Paz", "UNSLP", "Privada"),
  Universidad("Universidad de Aquino Bolivia", "UDABOL", "Privada"),
  Universidad("Universidad Tecnológica Boliviana", "UTB", "Privada"),
  Universidad("Universidad La Salle", "ULS", "Privada"),
  Universidad("Universidad Real", "UREAL", "Privada"),
  Universidad("Universidad Unión Bolivariana", "UUB", "Privada"),
  Universidad("Universidad Boliviana de Informática", "UBI", "Privada"),
  Universidad("Universidad San Francisco de Asís", "USFA", "Privada"),
  Universidad("Universidad NUR", "NUR", "Privada"),
];

const universidadesLaPazElAlto = UNIVERSIDADES_LA_PAZ_EL_ALTO;
