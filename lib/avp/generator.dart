class AvpGenDef {
  // """The class attribute name that holds the value for the AVP."""
  String attrName;
  // """An AVP code that the actual AVP will be generated from."""
  int avpCode;
  // """A vendor ID to pass on to AVP generation. Should be zero if no vendor

  int vendorId;
  // is to be set."""
  bool isRequired;
  // """Indicates that the class attribute must be set. A ValueError is raised
  // if the attribute is missing."""
  bool? isMandatory;
  // """Overwrite the default mandatory flag provided by AVP dictionary."""
  dynamic typeClass;
  // """For grouped AVPs, indicates the type of another class that holds the
  // attributes needed for the grouped sub-AVPs."""
  AvpGenDef({
    required this.attrName,
    required this.avpCode,
    this.vendorId = 0,
    this.isRequired = false,
    this.isMandatory,
    this.typeClass,
  });
}

typedef AvpGenType = AvpGenDef;
