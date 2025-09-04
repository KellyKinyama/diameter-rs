import '../diameter_rs.dart';
class AaMobileNode extends DiameterMessage{
    // """An AA-Mobile-Node base message.

    // This message class lists message attributes based on the current
    // [rfc4004](https://datatracker.ietf.org/doc/html/rfc4004) as python
    // properties, acessible as instance attributes. AVPs not listed in the base
    // protocol can be retrieved using the
    // [AaMobileNode.find_avps][diameter.message.Message.find_avps] search
    // method.

    // Examples:
    //     AVPs accessible either as instance attributes or by searching:

    //     >>> msg = Message.from_bytes(b"...")
    //     >>> msg.session_id
    //     dra1.mvno.net;2323;546
    //     >>> msg.find_avps((AVP_SESSION_ID, 0))
    //     ['dra1.mvno.net;2323;546']

    //     When diameter message is decoded using
    //     [Message.from_bytes][diameter.message.Message.from_bytes], it returns
    //     either an instance of `AaMobileNodeRequest` or `AaMobileNodeAnswer`
    //     automatically:

    //     >>> msg = Message.from_bytes(b"...")
    //     >>> assert msg.header.is_request is True
    //     >>> assert isinstance(msg, AaMobileNodeRequest)

    //     When creating a new message, the `AaMobileNodeRequest` or
    //     `AaMobileNodeAnswer` class should be instantiated directly, and values
    //     for AVPs set as class attributes:

    //     >>> msg = AaMobileNodeRequest()
    //     >>> msg.session_id = "dra1.mvno.net;2323;546"

    // Other, custom AVPs can be appended to the message using the
    // [AaMobileNode.append_avp][diameter.message.Message.append_avp] method, or
    // by overwriting the `avp` attribute entirely. Regardless of the custom AVPs
    // set, the mandatory values listed in rfc4004 must be set, however they can
    // be set as `None`, if they are not to be used.

    // !!! Warning
    //     Every AVP documented for the subclasses of this command can be accessed
    //     as an instance attribute, even if the original network-received message
    //     did not contain that specific AVP. Such AVPs will be returned with the
    //     value `None` when accessed.

    //     Every other AVP not mentioned here, and not present in a
    //     network-received message will raise an `AttributeError` when being
    //     accessed; their presence should be validated with `hasattr` before
    //     accessing.

    // """
   CommandCode code = CommandCode.fromCode(260);
   String name= "AA-Mobile-Node";
   AvpGenType avpDef;

   AaMobileNode():super(header: DiameterHeader(length: 20, flags: flags, code: code, applicationId: applicationId, hopByHopId: hopByHopId, endToEndId: endToEndId), dict: )

    // def __post_init__(self):
    //     self.header.command_code = self.code
    //     super().__post_init__()

    // @classmethod
    // def type_factory(cls, header: MessageHeader) -> Type[_AnyMessageType] | None:
    //     if header.is_request:
    //         return AaMobileNodeRequest
    //     return AaMobileNodeAnswer

    factory AaMobileNode.fromDiameterMessage(DiameterHeader header){
if(header.isRequest)        return AaMobileNodeRequest;
         return AaMobileNodeAnswer;
}
}