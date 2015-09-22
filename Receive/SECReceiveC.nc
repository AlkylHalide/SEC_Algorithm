configuration SECReceiveC {
	
}

implementation {
	components SECReceiveP,
	MainC,
	ActiveMessageC,
	new AMSenderC(128),
	new TimerMilliC,
	LedsC;

	SECReceiveP.Boot -> MainC;
	SECReceiveP.SplitControl -> ActiveMessageC;
	SECReceiveP.Led -> LedsC;
	SECReceiveP.AMSend -> AMSenderC;
	SECReceiveP.PacketAcknowledgements -> ActiveMessageC;
	SECReceiveP.Timer -> TimerMilliC;
}