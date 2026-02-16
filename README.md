tcpmon:
Command line program to examine tcpdump output, to approximate randomness of the packet contents and whether their contents are random. 
This program aggregates packet captures, and uses gzip to compress its contents. The rate of compression acts as shorthand to evaluate whether the packets are encrypted. 
If the packet contents are encrypted, we should expect to see a low rate of compression / inefficient compression ratio. 

This program 
