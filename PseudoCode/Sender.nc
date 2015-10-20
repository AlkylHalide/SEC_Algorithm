/** Local variables **/
AltIndex = 0; 			// Varies between {0, 1, 2}

ACK_set[capacity+1]; 	// Elements are acknowledgement packets
						// Each element: <ldai; lbl>

/** Interface **/
Fetch(NumOfMessages)	// Fetches NumOfMessages from application layer and returns
						// them in array with size NumOfMessages (in original order)

Encode(Messages[])		// Receives array M of messages, each message has length ml
						// Returns array M' of messages in equal size to M
						// M'[i] is the encoded version of M[i]
						// Final length of returned M'[i] is n
						// Code can bare "capacity" mistakes

/** Function packet_set() **/
pckt packet_set()									// packet_set() krijgt als input de
for_each (i,j)										// geëncodeerde array 
	data[i].bit[j] = messages[j].bit[i];
return pckt = <AltIndex, i, data[i]> } (i = {1,n})

/** Main function, do forever "send" loop of the algorithm **/
do
{
	if({AltIndex x [1, capacity+1]} € ACK_set) {
		AltIndex = (++AltIndex % 3);
		ACK_set = 0;
		messages = Encode(Fetch(pl));
	}
	for_each pckt € packet_set() do
		send(pckt);
} while (1);

/** Upon receiving an ACK(<ldai, lbl>) **/
if (ldai = AltIndex AND lbl € {1, capacity+1})
{
	ACK_set.append(ACK);
}


/** Werking uitgelegd: **/

// Fetch(NumOfMessages) haalt NumOfMessages op van de applicatie laag en returned deze in een 
// array met qlengte NumOfMessages.

// Encode(Messages[]) krijgt als input een array van messages M die elke lengte ml hebben:
// length(M[i]) = ml, met i € [1,pl].
// Al deze berichten worden individueel geëncodeerd volgens Error Correction Codes.
// Als resultaat returned deze functie een array M' met dezelfde lengte als M.
// De messages in M' zijn echter langer, ditmaal lengte n, omdat er <capacity> aan Error
// Correction Bits zijn toegevoegd:
// length(M'[i]) = n, met i € [1,pl].

// De functie packet_set() krijgt als argument (input) een array aan geëncodeerde messages,
// dit is het resultaat van de functie Encode() M'.
// packet_set() beschouwt deze array als een bitmatrix en transponeert deze.
// Deze functie returned vervolgens paketten met als inhoud <AltIndex, i (lbl), data[i]>
// met i € [1,n]

// Het hoofdgedeelte van het algoritme bestaat uit een 'do forever' loop met volgende stappen:
// Als {AltIndex x [1, capacity+1]} een deelverzameling is van ACK_set:
// 	-> (AltIndex + 1) mod 3
// 	-> ACK_set leegmaken
// 	-> messages = Encode(Fetch(pl))
// Vervolgens een foreach loop waarbij packet_set() wordt opgeroepen en elk pakket verstuurd
// wordt met de functie send().

// Het laatste gedeelte behandelt het ontvangen van Acknowledgement berichten.
// ACK berichten bestaan uit <ldai, lbl>
// if (ldai = AltIndex) EN (lbl € [1, capacity+1]) {
// 	voeg de ontvangen ACK toe aan ACK_set
// }