## Copyright (C) 2026 dennis.hueber ISS
##
## Author: dennis.hueber <dennis.hueber@DDH>
## Created: 2020-02-14
##updated  7 2026 using tcpclient.


%Uses the instrument-control package.
%This is an Octave function that reads a line of text from the input buffer
%of an an open tcpip object.  End of line is defined by CR and LF (13 10) in
%ascii characters in sequence. The data (od) and number of bytes (n_bytes) area
%returned.  Use instrument-control to set a timeout for the fread function.
%The CR and LF characters are included in the array output, if they are not
%present timeout was reached. If no data is read od(1) will be NULL character
%od will be length 1.

%In Matlabe use of this function could likley just be repalced in with getl(), with
%the terminator set to character 10 / line feed FD.  Although DMC will always send
%both CR and LF at the end of a message, it will not send any LF by themselves in text
%mesages. Accept possible in the HELP responce text. Just do not send a HELP command
%except at the beginning when no other responce is expected. Remove the entire help
%text fromt the input TCPIP buffer before issuing any other commands or reading
%text responces.  True even if you look for CR and LF together like this function.

%In all cases this fucntion shoudl not be used to read the bineary data sent by DMC,
%bytes equal to 10 and 13 will occure randomly in bineary data.

%BTW I found no need for a writeln (or writel) function, that's can be done just by
%sending the EOL characters at the end of the text command with low level TCPIP
%write functions.


function [od,n_bytes] = tcpclient_readln_CRLF(tc)
  timeout=false;
  n_bytes=0;
  od(1)=0;  %null character
  LastCharWasCR=false;
  EOL_Detected=false;
  while ((!EOL_Detected)&&(!timeout))
    c=read(tc, 1, 'char');
    n=numel(c);
    if (n!=0)
      n_bytes++;
      od(n_bytes)=c;
      if (!LastCharWasCR)
        if (c==13)
          LastCharWasCR=true;
        else
          LastCharWasCR=false;
        endif
      else   %the last character was a CR
         if(c==10)
            EOL_Detected=true;
         endif
      endif
    else
      timeout=true;
    endif
  endwhile
endfunction









