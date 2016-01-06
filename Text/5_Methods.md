METHODS
Describing How You Solved the Problem or Answered the Question

Tools
Like I discussed earlier, the work of my thesis has several goals. One of them is providing a solid starting point for a continuation of this research into future work, in case a replication of my experiments is needed. In this part I’ll discuss the tools I used to implement and evaluate the S²E²C algorithm. By giving a description of the used materials, future research can start from my exact situation. This way I provide all the variables of this project in the form of this thesis.

TinyOS

TinyOS is a free, open-source, flexible and application-specific embedded operating system designed for low-power wireless devices, specifically targeting Wireless Sensor Networks (WSN). It was developed by the University of Berkeley California and has since grown to be an international consortium, the TinyOS Alliance. The initial release was in 2000. At the time of writing the latest release, and the version I worked with to implement the algorithm, is version 2.1.3 and was released in 2012.

Wireless sensor networks usually consist of a large number of small nodes, which are designed to operate with strict resource constraints concerning memory, and power consumption. Examples include, but are not limited to, sensor networks, ubiquitous computing, personal area networks, smart buildings and smart meters. These limited resources and low-power characteristics require a smart operating system that can withstand these challenges and successfully handle high load operations while maintaining a certain level of quality in execution. TinyOS meets these challenges and quickly became the platform of choice for sensor network research.

Often the comparison is made between TinyOS and other methods for developing applications on embedded systems. An example of one such method are the popular Arduino microcontroller boards. At at higher level, Arduino is lighter weight than TinyOS. The reason for this is simple; Arduino only offers some simple C support for microcontrollers and sensors. TinyOS on the other hand, is a fully developed operating system. Consequently, while it is very easy to get started with Arduino, the learning curve for TinyOS is quite steep. For advanced and powerful applications, and large WSNs however, this pays off in TinyOS’ advantage. Especially applications with elements such as multi-hop routing, reliable dissemination and time synchronization require a decent operating system that can efficiently handle these complex operations.
[http://tinyos.stanford.edu/tinyos-wiki/index.php/FAQ]
[https://en.wikipedia.org/wiki/TinyOS]
[http://www.ijcst.com/vol61/1/32-Praveen-Budhwar.pdf]

nesC
TinyOS itself and it’s applications are written in nesC, a programming language specifically designed for networked embedded systems. It uses a programming model that incorporates event-driven execution, a flexible concurrency model, and component-oriented application design. nesC improves reliability and reduces resource consumption by including data-race detection and aggressive function inlining. It achieves this by having restrictions on the programming model. In their initial presentation of the language, the original developers acclaim that based on their experience and evaluation of the language it shows that it is effective at supporting the complex, concurrent programming style demanded by the new class of deeply networked systems such as Wireless Sensor Networks.
[http://www.tinyos.net/papers/nesc.pdf]

The use of this new programming language makes programming in TinyOS challenging. On one hand, nesC is quite similar to C. This means that implementing new features or protocols usually isn’t hard. The difficulties arise when trying to incorporate new codes into existing ones. The part where nesc and C differ greatly is in the linking model. Writing software components isn’t very difficult, but combining a set of components into a working application is quite challenging and complex. Unfortunately this is something that I was forced to do throughout the implementation process of my thesis. As I will discuss later in this report, this made my work quite difficult at times.
[http://csl.stanford.edu/~pal/pubs/tinyos-programming-1-0.pdf]

TinyOS can function on a number of supported hardware platforms. For my thesis, the hardware that was used is the TelosB Mote Platform. This is the platform used for most of the WSN research at Chalmers. It is a low power Wireless Sensor Module, and it is composed of the MSP430 microcontroller and the CC2420 radio chip. The microcontroller of this mote operates at 4.15 MHz and has a 10 kBytes internal RAM and a 48 kBytes program Flash memory.

All of my algorithm tests and experiments were performed in the form of simulations. This means I did not use actual hardware. Instead, the simulator provided an simulation image of the TelosB mote. By doing this I was able to replicate real life experiments very accurately, since the compiler makes sure my application was compiled specifically for TelosB motes, by providing the telosb command as an argument to the compile function.
[http://www.willow.co.uk/html/telosb_mote_platform.php]

TOSSIM
TOSSIM is the standard simulator for TinyOS. The newest version can always be found in the TinyOS source directory when you install it, since TOSSIM is a standard part of TinyOS. It simulates entire TinyOS applications, and works by replacing components with simulation implementations.

For my research I have not used TOSSIM. Instead I was instructed, during the explanation of my assignment, that I would use Cooja (explained later). This means I will not go into further detail on TOSSIM, but further details can be found on the wiki page. [http://tinyos.stanford.edu/tinyos-wiki/index.php/TOSSIM]

Cooja
Cooja is the WSN simulator I used for my research. It comes standard with a version of Contiki-OS, and has a few advantages over TOSSIM. It has advanced capabilities, active support, and it can work with or without a GUI. This gave me more flexibility for simulating the algorithm. An added advantage is that the GUI allows for a smaller learning curve, which meant quicker testing and development.

Contiki-OS or in short Contiki, is the self pronounced “Open Source OS for the Internet of Things”. In contrast to TinyOS, it is being commercially developed and supported.
[http://www.contiki-os.org/index.html]

When it comes down to it, Contiki and TinyOS and different operating systems with the same goal: to develop applications with a small footprint, targeting low-power devices as used in WSNs. My application is developed in TinyOS for TelosB motes, but I’m using the Cooja simulator from Contiki. This means using a slightly different approach of simulating applications, but luckily it is not difficult at all. The following steps need to be taken to simulate code based on TelosB motes in Cooja.
Cooja is included in the Contiki CVS Git. Hence, make sure you have a recent cvs checkout git clone of Contiki on your system.
```
git clone https://github.com/contiki-os/contiki.git
```
Compile the TinyOS application, by executing the appropriate make command in the project folder. For TelosB motes this means, executing the following command.
```
cd /path-to-project-folder/
make telosb
```


Open Cooja. Select File → New Simulation → Create.
Select Motes → Add motes → Create a new mote type → Sky Mote
In the Contiki Process/Firmware field browse to the location on disk where you’ve compiled your code using make telosb
1. File->New Simulation. Create.

2.Motes->Add Motes->Create a new mote type->Sky Mote

3.In the Contiki Process/Firmware field browse to the location on disk where you’ve compiled your code using make telosb

4.Go to build/telosb/ and choose main.exe

5.Add motes

LibReplay


Scripts
All simulation and test scripts were developed in bash, the standard Linux scripting environment.

Github
The most used Version Control System (VCS) for distributed revision control and source code management (SCM) on the internet is Github. It is based on Git, which is a widely-used, free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency. It provides a flexible and fast Linux client as well as a web-based graphical interface.
I have used it for the whole duration of my work for a safe place to store the code, and revert back to working code in case something went wrong. Therefore all the source code for my thesis will be made available at https://github.com/AlkylHalide/SEC_Algorithm.
[https://git-scm.com/]
[https://en.wikipedia.org/wiki/GitHub]

Atom
Atom is my preferred code editor for this implementation and subsequent research. This section may seem irrelevant and a waste of space, but I am giving it a small section here because it has been vital for me in writing the code for the algorithm. The reason for this is that I searched very long for some kind of editor/IDE that had support for the nesC language. Unfortunately all my search efforts were in vain, until I came across Atom. To the best of my knowledge at the time of writing, it is the only out-of-the-box solution that support the nesC programming language natively without requiring any other plugin or extra package.

Algorithm

### FROM: https://github.com/AlkylHalide/SEC_Algorithm/blob/master/README.md #####

Structure

There are four main folders in which a version of the algorithm can be found. Each new version builds upon the previous one and adds functionality, as explained below. This makes it easy to quickly set up simulations and experiments for each version, and allows to quickly compare code of each version if needed.

The four versions are:

First-Attempt
Advanced-No-ECC
Advanced-ECC
Advanced-ECC-Multihop
All versions work through point-to-point communication. This means a Sender sends his messages to one specific Receiver, and the Receiver acknowledges the messages back to the original Sender.

First-Attempt

This is the first attempt version of the algorithm as described in the original paper. The Sender sends each message with an Alternating Index value and a unique Label for each message. The Receiver acknowledges each message upon arrival and the Sender will only send the next message if the current one has been properly acknowledged. Once the Receiver receives a certain amount of messages, the algorithm delivers these messages to the Application Layer. The variable CAPACITY determines this amount of messages in the network, the value of which can be adjusted according to the needs of the implementation in the algorithm itself.

Advanced-No-ECC

These are the full Sender and Receiver algorithms as described in the paper. On top of the basic first attempt functionality the algorithm divides the messages in packets and sends them to the Receiver. There is no implementation of Error Correcting Codes in this version yet. The point of this is to observe the performance of the algorithm without the Error Correction Codes, and then compare it with the performance of the algorithm once the Error Correcting Codes are added. This way it is much easier to see if the possibly increased performance of the algorithm thanks to the Error Correcting Codes weigh up against the added overhead that they bring along.

Advanced-ECC

This version contains the full Sender and Receiver algorithm as described in the paper. This is the First Attempt algorithm, together with the Packet Generation functionality, and the Error Correcting Codes.

Advanced-ECC-Multihop

In a real-life situation, it is very likely that the Sender and Receiver nodes are not within radio distance of each other. To fully observe the performance of the algorithm in such a real-life environment, it is therefore necessary to add the functionality of Multi-Hop routing through an appropriate Multi-Hop algorithm. In this case we have chosen for the IPv6 Routing Protocol for Low Power and Lossy Networks (RPL, pronounced 'Ripple'). As you will be able to see in the code, this brings along significant changes to the Sending and Receiving algorithm. The reason is that this protocol uses UDP functionality to send and receives messages. To do this it uses custom TinyOS UDP functions as defined in BLIP 2.0 (Berkely Low-Power IP Stack).

Usage

We work with a separate Sender and Receiver algorithm. The code is therefore implemented in each version in two folders; Send and Receive. Each of these folder contains four files. I've made the naming conventions consistent for each file. I will show the structure for the Send algorithm, but it is identical to the Receiver algorithm except for the file names.

1. Makefile

You can customize all the Makefile options if you need something changed. I'll explain the two most useful ones here, for the rest I refer to the TinyOS documentation and specifically BLIP 2.0. Both of these options are only available in the Multi-Hop version.

CFLAGS += -DRPL_ROOT_ADDR=11 This changes the address of the root node in the RPL network. The number represents the node id. You can change this to any arbitrary node id in the network.

PFLAGS += -DIN6_PREFIX=\"fec0::\" With this you can set the IPv6 prefix used to address the nodes in the network.

I've implemented the Printf functionality in all the versions of the algorithm. To use it, simply use the standard printf() C-function followed by the printfflush() function to write the information to the node output.

2. SECSend.h

There are two AM_TYPE numbers declared for the messages sent between Sender and Receiver. This way you can multiplex the radio channel. Again you can change this to any arbitrary number.

AM_SECMSG = 5
AM_ACKMSG = 10
Two different messages travel across the network:

SECMsg: the data messages from the Sender to the Receiver
ACKMsg: the acknowledgement messages from the Receiver to the Sender
typedef nx_struct SECMsg {
  nx_uint16_t ai;
  nx_uint16_t lbl;
  nx_uint16_t dat;
  nx_uint16_t nodeid;
} SECMsg;
SECMsg defines four fields:

ai: the current Alternating Index
lbl: the label of the message, which is unique for each message in relation to the current Alternating Index
dat: the data it contains. In my algorithm this is simply an incrementing counter value.
nodeid: the nodeid of the Sender
typedef nx_struct ACKMsg {
    nx_uint16_t ldai;
    nx_uint16_t lbl;
    nx_uint16_t nodeid;
} ACKMsg;
ACKMsg defines three fields:

ldai: the Last Delivered Alternating Index value
lbl: the label of the message, which is the label of the incoming message for which the Receiver acknowledges the arrival.
nodeid: the nodeid of the Receiver
3. SECSendC.nc

This is the Configuration file for the TinyOS application. Unless you want to add new functionality to the algorithm, you should not change anything in here.

4. SECSendP.nc

The Component file includes the actual operational logic of the algorithm. Here you can adjust three elements.

The capacity of the network, as described in the original paper, is determined using this variable. This comes down to how many messages the Receiver will collect before delivering them to the Application Layer. #define CAPACITY 15

In the packet generation function, there are two predefined values. This function looks at the array of messages, which are fetched from the Application Layer at the Sender side, as a matrix. It then transposes this matrix to generate the packets that will be send over the network.

ROWS defines the amount of messages that are retrieved from the Application Layer. Basically this comes down to the length of the array of messages. Since the original paper specifies that the algorithm fetches (CAPACITY + 1) messages from the Application Layer on the Sender side, this value is set by adjusting the CAPACITY variable. #define ROWS (CAPACITY + 1)

COLUMNS defines the length of each message in the array of fetched messages, on a bit level. The counter values, which are sent as the data part of each message, are defined as uint16_t or unsigned 16-bit integers. The bit-wise length of each message is therefore 16 bits (the data part at least), which motivates my choice to put the COLUMNS variable at 16. #define COLUMNS 16

I've created this variable to make the algorithm easily scale according to the amount of nodes being used in the network. Since each Sender sends to one specific Receiver and vice-versa, the amount of Sender-nodes in the network (which should be equal to the amount of Receiver nodes) determines the address node id of the Receiver and Sender mote in each respective algorithm. #define SENDNODES 3


First attempt algorithm
Unit testing
Packet formation from messages
Error correction codes
Multi-hop routing algorithm

Simulations
Single-hop setup
Multi-hop setup
Automating simulations using test scripts

Experiments
LibReplay setup
