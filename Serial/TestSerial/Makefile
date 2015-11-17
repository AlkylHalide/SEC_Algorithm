COMPONENT=SerialAppC
BUILD_EXTRA_DEPS += Serial.class
CLEAN_EXTRA = *.class SerialMsg.java

CFLAGS += -I$(TOSDIR)/lib/T2Hack

Serial.class: $(wildcard *.java) SerialMsg.java
	javac -target 1.4 -source 1.4 *.java

SerialMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=SerialMsg Serial.h serial_msg -o $@


include $(MAKERULES)

