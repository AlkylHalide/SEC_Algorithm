/** Unit testing the S²E²C algorithm **/

/**
Eisen:

1. Fetches a number of messages 'm'

2. Encodes messages according to the method in Figure 2 of the paper.

3. Sends messages to receiver concurrently (non-stop)

4. Receiver receives messages

5. Receiver can decode messages

6. Receiver acknowledges packets (repeatedly)

7. Sender receives acknowledgements

8. Sender transmits new message when ACK arrives

9. Sending packets contain <ai, lbl, dat> with m = <dat>, ai = [0,2] = state alternating index, lbl = distinct packet labels
**/

/**
PART 1: End-to-end protocol (first attempt)
**/

/**
PART 2: Full S²E²C algorithm (= first attempt + encoding)
**/