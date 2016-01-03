## S²E²C Algorithm
### *Self-stabilizing End-to-End Communication in (Bounded Capacity, Omitting, Duplicating and non-FIFO) Dynamic Networks*
### *A Practical Approach in TinyOS*

This is the main repository for my thesis work.
My assignment was to implement the algorithm developed by my supervisor, Elad Michael Schiller, in TinyOS and test in different circumstances to determine its practical functionality, advantages, and limitations.

The original paper can be found on the Gulliver Publications page:
http://www.chalmers.se/hosted/gulliver-en/documents/publications

The direct link to the full text is available here:
http://link.springer.com/chapter/10.1007%2F978-3-642-33536-5_14

----------------------------------------------------------------------

### Usage

There are four main folders in which a version of the algorithm can be found.
Each new version adds functionality as explained below.
This makes it easy to quickly set up simulations and experiments for each version, and allows to quickly compare code of each version if needed.

All versions work through point-to-point communication. This means a Sender sends his messages to one specific Receiver, and the Receiver acknowledges the messages back to the original Sender.

#### First-Attempt
This is the first attempt version of the algorithm as described in the original paper.
The Sender sends each message with an Alternating Index value and a unique Label for each message. The Receiver acknowledges each message upon arrival and the Sender will only send the next message if the current one has been properly acknowledged.
Once a certain amount of messages is received at the Receiver, these messages are delivered to the Application Layer.
This amount of messages in the network is determined by a variable called CAPACITY, which can be adjusted according to the needs of the implementation.

#### Advanced-No-ECC
Full algorithm without Error Correcting Codes

#### Advanced-ECC
Full algorithm with Error Correcting Codes

#### Advanced-ECC-Multihop
Full algorithm with Error Correcting Codes and Mult-Hop functionality
