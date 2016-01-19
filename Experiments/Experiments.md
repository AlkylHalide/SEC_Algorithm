# EXPERIMENTS

To assess the correct working of the algorithm we need to run it in a defined set of experiments. Objective measurement principles are used to gather the data and analyze the results. In this section of the work, we first describe the setup that is used, after which we run and discuss the experiments one by one.

## Setup

We execute the algorithm in a controlled simulation environment, in this case Cooja, according to a set of communication faults that we introduce in the system. We disturb the end-to-end communication by inserting faults that manipulate the packet flow from the sender to the receiver. We use four different possibilities of packet manipulation.

  - Omission
  - Insertion
  - Duplication
  - Reordering

In total we execute seven experiments. First we test the four different errors separately. Next we perform three different combinations of the errors.

The way we introduce faults into the system is by using a probability. This probability, expressed in a number smaller than one, defines the relative frequency at which packets are manipulated. In other words, this defines the chance for an error to occur should this be a real system.
We run each experiment six times, using a different probability each time. In total we make sure to have a good balance of probabilities. The difficulty herein lies in choosing a good probability. Should we choose this number too low, the effect of the errors will not be noticeable. If we choose it too high, the algorithm will succumb to the amount of overhead and block, i.e. it will not handle enough packets to accurately judge the performance.

For each experiment we use a setup of 20 nodes, 10 senders and 10 receivers, in a randomly placed fashion. Because of the multi-hop algorithm we also need to use two extra nodes; a root node and a node that acts as the router.

## Benchmarks

To test the algorithm we need an objective measurement which can represent the performance of the algorithm in function of the errors that we introduce. We use the number of iterations of the algorithm at the receiver side, as a performance indicator. The original paper in which the algorithm was described, gives a clear definition for an iteration.

*An iteration is said to be complete if it starts in
the loop’s first line and ends at the last (regardless of whether
it enters branches) \cite{dolev2012self} .*

## Experiment 1: omission of packets

In this first experiments we omit packets in the communication channel.
