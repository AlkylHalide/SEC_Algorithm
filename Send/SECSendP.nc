module SECSendP {
	uses {
		interface Boot;
		interface SplitControl;
		interface AMSend;
		interface Leds;
		interface PacketAcknowledgements;
		interface Timer<TMilli>;
	}
}

implementation {

	/**  AltIndex for the ABP protocol **/
	uint16_t AltIndex = 0;

	/** Message to transmit **/
	message_t myMsg;

	/** Array to contain the ACK messages **/
	/** HOW LONG ACK_SET??? At most <capacity+1> **/
	uint8_t ACK_set[10];

	/** Timer delay **/
	enum {
		DELAY_BETWEEN_MESSAGES = 50;
	}

	/** Prototypes **/
	task void send();

	/*********** Boot Events ***********/
	event void Boot.booted() {
		call SplitControl.start();
	}

	/*********** SplitControl Events ***********/
	event void SplitControl.startDone(error_t error) {
		post send();
	}

	event void SplitControl.stopDone(error_t error) {

	}

	/*********** AMSend Events ***********/
	event void AMSend.sendDone(message_t *msg, error_t error) {
		if (call PacketAcknowledgements.wasAcked(msg)) {
			
		} else {

		}

		/** This delay between messages is maybe not necessary **/
		/**if(DELAY_BETWEEN_MESSAGES > 0) {
			call Timer.startOneShot(DELAY_BETWEEN_MESSAGES);
    	} else {
			post send();
    	}**/
	}

	/*********** Timer Events ***********/
	event void Timer.fired() {
		post send();
	}

	/*********** Tasks ***********/
	task void send() {
		call PacketAcknowledgements.requestAck(&myMsg);
		if(call AMSend.send(1, &myMsg, 0) != SUCCESS) {
			post send();
		}
	}
}