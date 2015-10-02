// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#include <printf.h>
#include "SECReceive.h"

module SECReceiveP {
  uses {
    interface Boot;
    interface SplitControl as AMControl;
    interface AMSend;
    interface Packet;
    interface AMPacket;
    interface Receive;
    interface Leds;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as Timer0;
  }
}

implementation {
  
  /**  Variable to keep track of the last delivered alternating index in the ABP protocol **/
  uint16_t LastDeliveredAltIndex = 0;

  /** Label variable **/
  uint16_t recLbl = 0;

  /** Message to transmit */
  message_t ackMsg;

  /** Variable to store the source address of the incoming packet **/
  uint16_t src = 0;
  
  /***************** Prototypes ****************/
  task void send();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
  }
  
  event void AMControl.stopDone(error_t error) {
  }
  
  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    SECMsg* inMsg = (SECMsg*)payload;

    // src = call AMPacket.source(inMsg);
    // printf("Adres: \n");
    // printf("%d\n", src);

    printf("AltIndex: \n");
    printf("%d\n", inMsg->ai);
    printf("Label: \n");
    printf("%d\n", inMsg->lbl);
    recLbl = inMsg->lbl;
    printf("Data: \n");
    printf("%d\n", inMsg->dat);
    printfflush();

    if (inMsg->lbl == 11)
      LastDeliveredAltIndex = inMsg->ai;

    post send();

    //TODO: Add incoming SECMsg to packet_set[]
    
    return msg;
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
  }
  
  /***************** Timer Events ****************/
  event void Timer0.fired() {
  }
  
  /***************** Tasks ****************/
  task void send() {
    ACKMsg* outMsg = (ACKMsg*)(call Packet.getPayload(&ackMsg, sizeof(ACKMsg)));
    outMsg->ldai = LastDeliveredAltIndex;
    outMsg->lbl = recLbl;

    // TODO: AM_BROADCAST_ADDR is niet correct denk ik,
    // ACK messages moeten enkel teruggestuurd worden naar
    // de bron van originele incoming message

    if(call AMSend.send(AM_BROADCAST_ADDR, &ackMsg, sizeof(ACKMsg)) != SUCCESS) {
      post send();
    }
  }
}