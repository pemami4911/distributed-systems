# Bitcoin

The goal of this project is to create a distributed Bitcoin mining system. A supervisor creates tasks for workers to search for Bitcoins.
Each supervisor can generate as many processes as there are cores on the machine.
Other machines can request work to distribute the load across multiple machines.
The input is the number of leading 0's in the SHA256 hash for the bitcoin. The following string is appended to all candidates: "pemami".

The output are the Bitcoins with the corresponding number (or less) of leading 0's. 

## How to run

Build the project with

    mix escript.build

To start the server node, run 

    ./project1 --k 4 --ip #YOUR_IP_ADDRESS#

To add a worker node, run

    ./project1 --server #SERVER_IP_ADDRESS# --ip #YOUR_IP_ADDRESS#

## Leaderboard

| Coin with most leading zeros | String | Hash | 
| --- | --- | --- |
| 8 | pemami'A;rl)N7 | 000000001E450E87A534729604E28AEE0E855BFC8D08557FBDF72174A88E8D06 | 
| 7 | pemami(<Ttyuf | 0000000C6A2DBB3FE5193B6455EFCE8CD44765729AB286E417B95048A6AB828E |

### Most machines I tested with

3 machines (4 cores, 4 cores, and 8 cores)


### Work Unit

To distribute work amongst multiple cores and multiple machines, I used `Enum.random` to randomly sample strings of different lengths. 
I take the current highest number of cores in use, add the new machine's number of cores, and then add 5 to that. 
As an example, if the server node has 4 cores, it will run 4 processes and randomly sample strings (ASCII values between 33 and 126) of length 9, 8, 7, and 6 to append
to "pemami". Then, if a worker with 8 cores requests work, it will randomly sample strings of length 17, 16, ..., 10. 

I determined that this implementation would optimally balance between simplicity and non-overlapping sub-problems for all cores and worker machines.

## Results for k=4

```
SE-11783:~/Workspace/distributed-systems/project1$ ./project1 --k 4 --ip 10.245.36.29
Starting server at server@10.245.36.29. Listening for new workers.
pemami?9/;-i    0000C6097617D97DEC5BC8C8E0A33E8C9C15C90DE9664C50ECF36A1B1E99E51F
pemamixBgs/d    0000BB9583DC617BC77DD3ACF544B041BE4449BF5F9554B60E6F9DDFE50B9F7E
pemamieNcdU8S^  00001216A012BD33D9F5067CE68EC0FEE616A83545AACB31ADD141361126922C
pemamiEcPhvaF   0000F80C7570F77142DAB56B830FB7C6DB4F86F19ECDE4F8DC9799F30F1190B8
pemamii(F2.9    0000A0AFB82296AC3887B81AB2B8C3C46E9B2E2A790E8BE74C961F9E1BE414DD
pemami=dlc!DW   000008963C6C60AE96722B2F58396C8135A015DA27CEC5F7B0CFEC06E4D7F07C
pemami-l>Pb#p&@ 0000A1CADC7131504F8BB319242BFE112BD7EA51629AF94CBB1014C474F9F347
pemamiMSO*J573: 0000A741CD76DA2E6AEF8149AB8CFDA6EE8DCD9FF6F20E110B76D4C60AF94B3A
pemami6HJ=03D4/ 00002E37E1C95957A6AFD5491F8955DD1FAB277FE447C87B2D2D742241B7A040
pemamiN=@d8KI   0000B2E255177C22C7F497ACC049E8EB9FB3D2D91CED96C01720C1E07990E1B0
pemamiJ@ac8$7Y  00003B52332730B114F5A4147F78AA2D68033C72EB034B33420F3AF4F5CEFFF8
pemamiF8c,V^qJj 000036F8DE67EA1D7EFEAE782DC11EF8C583C15DB051664121564D350B593CEC
pemamiYCIgFE9q  0000F4904A11CF2B545CD523E289A5C2E2982CDCBC2F8D4F22E4123C40A50708
pemamiunf%r*J"  000012E29EDC69D7B481FC8B576303F69339BDDFD3D8162A44EAB6196F58B784
pemami]j\~(V#+  0000B4911CD599B4AC69B4355D0D065F6C2158B2A1DDC672CD1DE354BF357BF1
pemami{azm_`"*u 00006D885B6AF0D2BDDA689927DDB0ECED75075FECF8C52C19B61C92B969ED8C
pemamicYGdx3    0000618EFB5B004E3B6AD2B32151CF81F190C54127CE564DED31D69638AD1F64
pemamiA:I[}>m   000016635CF916DC3A0F832298A8BD1B43906873B7560F98A216D5B39EEB7185
```
 
#### Example Timing

* real: 39m32.269s
* user: 152m58.596s
* sys: 0m43.400s
* utilization: 0.2577
