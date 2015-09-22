configuration SECSendC {
	
}

implementation {
	components SECSendP,
	MainC,
	ActiveMessageC,
	new AMSenderC(128),
	new TimerMilliC,
	LedsC;

	SECSendP.Boot -> MainC;
	SECSendP.SplitControl -> ActiveMessageC;
	SECSendP.Led -> LedsC;
	SECSendP.AMSend -> AMSenderC;
	SECSendP.PacketAcknowledgements -> ActiveMessageC;
	SECSendP.Timer -> TimerMilliC;
}