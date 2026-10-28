clear all      % erase any existing data, causes functions to reload?
pkg load 'instrument-control'

commandwindow();

%A simple script to get help, read a single status packet and read a single data packet form DMC
%Not meant as an exmaple of continous data acqustiion (not likley fast enough).
%Really an example of interacting with DMC and parsing the binary data packts.
%Uses the following functions. The only output is to the consol.
%TCP_readln_CRLF - to read a line of text form the TCPIP input buffer until a CR and LF is found.
%DMC_readStatus - read the bineary status packet (starting after the text message the proceeds it).
%DMC_readData - reads one data packet. Only tested with DMC defaults.  Switch-8 multiplex frequency mode,
                                  %with number of cycles set to 8 (the default for DMC).
%Octave has perferred functions for TCPIP, but I will try to use the more matlab compatable when possible.
%Even so, this is very unlikely to work in Matlab. But hopefully the idea is knowledge needed is still
%similar.

%With DMC messages\commands are text ending in CR and LF characters. (both input commands, and output
%messages. After a command (text ending in CR LF) is sent to DMC, it will acknowledgment.  If it does
%not understand the command, you might get a unknown command message in return, if it does. The next
%string sent by DMC will a ascii text asknolegment message (ending in CR LF).

%The commands and  messages are (mostly) listed in the HELP command responce, this example sends a HELP
%command and displays the help message. But in a real program you would not do this.

%When commanded to send data or status packets, boxy will send binary data packets.  The binary data
%packets are always proceeded by a text (CF LF terminated message) and followed by a CR LF terminated
%text message.

%For example, after a "100 data starts:..." (with termiated CF LF) message, there will be a
%binary packet of data, followed by a "100 data stops:..." message. Also after a "100 status starts:..."
%messasge there will be a binary packet. After binary status packets, there is a "100 status stops:"
%message. The pattern will not be interlaced  any other way.  However, other messages like
%acknowledgments, might come after another text message, but never betwen "100 data starte:" and
%"100 data ends".  So after seeing a data starts message, you may parse the bineary datapacket without
%checking for any other message inside the datapacket.

%Again, the this example script asks for and gets one status packet and one data packet.
%Since it is slow, it might recieve two or more data packets before it stops data acqusition.
%It might be fast enough in Matlab, it might be better to create a mex file for more efficient
%reading messagaes and data packets. There might be a better way to vectorize the process.


%in 2026 updated to use tcpclient class ratehr than tcpip

printf("\nAttempting to connect to server now...\n");
t = tcpclient('127.0.0.1', 5556);
%t = tcpip('127.0.0.1', 5556) %Create a TCP/IP object associated with the host 127.0.0.1 (local machine), port 5556.
printf("\ntpcclient called.\n");

%fopen(t) %I'm thinking this does nothing in octave but matlab needs it.

def_timeout=.01;
set(t,'Timeout',def_timeout); %could have called tcp_timeout(t,,1) %timeout to 100ms, older
printf("\nDefault timeout set to: ");
t.Timeout
WM = read(t, 4, 'char');
%WM=fread(t,4,'char');%get the first 4 characters in the w%elcome messsage, these characters will be the text '100 '
                    %although we fetch then as characters, they are one byte numbers when returned. We could acces
                    %like this BM(1) the number 49, but ascii character 49 is '1', so char(BM(1)) will be '1'
                    %This is just an example of using fread with a timeout.
char(WM)  %print as text, char() interprets bytes as ascii text and diplays them, since no ;
t.Timeout=0.5; %set a long timeout, likely do not need to
TM=read(t,2048);%
%TM=tcp_read(t,2048,200);%get the welcome/connetion message, it should be there instantly.
                        %might be octave only, not sure about instant in matlab, the 200 is the
                        %timeout for this one call.
                        %Function will return all the bytes found in the input after
                        %200, or immediatly if there are 2048 bytes already there.
                        %in matlab maybe use fread and set(t,'timeout',X)
                        %assuming this is 2048 bytes or less.
t.Timeout=def_timeout; %return to default timeout.


char(TM)  %print as text

%Ask for and get the help mesage, let's play with how long it takes.
%flushinput(t);  %if there is anythign left, dump it
%and just for laughs, how much is already in the buffer?
printf("\nSending HELP command...\n");
printf("\nReading help text; with1 no wait and after some time.\n");
message="HELP\n\r";
write(t,message);
t.Timeout=.00;
HM=read(t,10000,'char');
t.Timeout=def_timeout; %return to default timeout.
char(HM)  %print as text
t.Timeout=.5; %make sure we wait for the entire rest of the message now
EHM=read(t,10000,'char');%call this one more time to be sure the input buffer is empty now?
t.Timeout=def_timeout; %return to default timeout.
printf("\n\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n");
char(EHM)  %print as text


%get a instrument status message, but use a DMC_readln (reat a line of text) function in the
%process.  Matlab might have a readln function, but octave does not have one for TCPIP
printf("\nSending GET_INSTR_STATUS_ONCE command.\n");
message="GET_INSTR_STATUS_ONCE\n\r";
flushinput(t); %make sure input buffer is empty.
write(t,message);  %we expect a command acknowledgment immediatly, but the actual status might take some time.
t.Timeout=def_timeout; %return to default timeout.
[TM,bytes]=tcpclient_readln_CRLF(t);
char(TM)

t.Timeout=1;
[TM,bytes]=tcpclient_readln_CRLF(t);
t.Timeout=def_timeout; %return to default timeout.
char(TM) %one should really check this, to insure it is a "100 status starts:... : message, but not for this example, just assume it is.
num_bytes=sscanf(char(TM),"100 Status Starts:%d");
if (num_bytes==436)
  DMC_Status=tcpclient_DMC_readStatus(t);
  printf("\nBinary status block read.\n");
  printf("Status block reports ip address of data client is %s\n",char(DMC_Status.DataClientIPAddress));
else
  printf("FAILED TO GET STATUS\n");
  DMC_Status="";
endif
[TM,bytes]=tcpclient_readln_CRLF(t);
char(TM)


%Now start data acqustion and retrieve one data message.
flushinput(t); %make sure input buffer is empty.
printf("\nSending START command.\n");
message="START\n\r";
write(t,message);  %we expect a command acknowledgment immediatly, but the data might take some time.
t.Timeout=def_timeout; %return to default timeout.
[TM,bytes]=tcpclient_readln_CRLF(t); %the help message give room for 58 bytes, which is the length of the acknowledgment I'm expecting
char(TM)
t.Timeout=1.5; %again data might take some time
[TM,bytes]=tcpclient_readln_CRLF(t);
t.Timeout=def_timeout; %return to default timeout.
char(TM)
num_bytes=sscanf(char(TM),"100 Data Starts:%d")



if (num_bytes>0)
  DS=tcpclient_DMC_readData(t);
  data_read=true;
else
  printf("FAILED TO GET DATA\n");
  data_read=false;
endif

[TM,bytes]=tcpclient_readln_CRLF(t);
char(TM)

printf("\nSending STOP command.\n");
disp(" ")
disp(" ")
message="STOP\n\r";
write(t,message);


%//////////////////////////////////////////////////////////////////////////////
disp "Messages Recieved after Stop sent..."
disp ("");

[TM,bytes]=tcpclient_readln_CRLF(t);
message=char(TM)  %Might not be the STOP acknowledgment, might be, might not be.
                  %the start of the next data message already in the input buffer?
                  %if it is a new data starts message, the entire datapacket
                  %should be available shortly, a stop command will not
                  %stop mid packet, any data starts message will always go wtih a
                  %full data packet and a data stops message.  Then we might find
                  %the stop acknowledgment. Because octave is slow, we might even
                  %get two more data packets.
%Read all the extra data packets that might be in the buffer (but we really do
%have to do it at this piont.)  But read them just as example, they would be
%if there are data packets, they would be valid, just sent before DMC recieved
%the stop command.
StopAcknowledgedOrError=false;
while (StopAcknowledgedOrError==false)
  aa=min(numel(message),13);
  bb=min(numel(message),16);

  if  ((substr(message,1,aa)=="200 STOP_DATA")||(substr(message,1,bb)=="100 Data Starts:")) ;
     if (substr(message,1,aa)=="200 STOP_DATA");  %message is longer, but 13 characters is enough
        StopAcknowledgedOrError=true;
     else
        tcpclient_DMC_readData(t); %just read, do not save or futher mention.
        [TM,bytes]=tcpclient_readln_CRLF(t);
        message=char(TM)  %this should be the end of data packet message
        [TM,bytes]=tcpclient_readln_CRLF(t); %read the next message, it might be stop acknowledgment
        message=char(TM) %loop this while again and see if there is more data.
     endif
  else
    StopAcknowledgedOrError=true;  %the message shoudl be one of the two above, so error if we are here
    disp "Error - did not recieve expected message"
  endif
endwhile


if (data_read)
  %only interested in the first data packet read after which shoudl be in DS structure
  printf("\nBinary data block read.\n");
  printf("Data block header reports size of one cycle = %d\n",DS.sizoef_one_cycle_of_data);
  printf("Data block header reports number of cycles = %d\n",DS.NumCyclesPerDataPacket);
  disp "Array of MagicNumbers read at end of binary data block, all should be 1234567890.  If they are, we are in sync!"
  DS.CycleDataHeader.MagicNumber2
  disp ("");
  %Assuming switch-8 frequency multiplexed, we can assign meaning to the floating points in the big data matrix.
  %note the the first dimension (column) is data cycle number.
  disp "DC data from detector A time multiplex channel 1"
  DS.CycleSignalData(:,1) %row 1 is the first data in each cycle, which is always detector 1 emitter (time multiplex channel 1) DC
  disp "DC data from detector A time multiplex channel 8"
  DS.CycleSignalData(:,(17*7)+1)  %17 double in each subchannels data
  disp "DC data from detector B time multiplex channel 1"
  DS.CycleSignalData(:,(17*8)+1)  %17 double in each subchannels data (in swithc-8 there are 8 time mulitplex channels.
endif



%OK that is the end of the demo, almost...
%Testsome RGB diodes

%set an indicator LED or 3, string 1 (not string 0)
message="SET_LED_POW_COL 1 0 255 0 0\n\r";
write(t,message);  %we expect a command acknowledgment immediatly, but the data might take some time.
message="SET_LED_POW_COL 1 1 0 255 0\n\r";
write(t,message);  %we expect a command acknowledgment immediatly, but the data might take some time.
message="SET_LED_POW_COL 1 2 0 0 255\n\r";
write(t,message);  %we expect a command acknowledgment immediatly, but the data might take some time.

[TM,bytes]=tcpclient_readln_CRLF(t);

%close out the connection and end script



flushinput(t);
clear t
%fclose(t);
%tcp_close(t);
