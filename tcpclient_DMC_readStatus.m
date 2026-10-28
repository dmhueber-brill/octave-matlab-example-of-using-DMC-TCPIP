

## Author: dennis.hueber <dennis.hueber@DDH>
## Created: 2020-02-14
## updated to use tcpclient class 7 2026

function DS = tcpclient_DMC_readStatus (tc)

%we are going to ignore the pad elements, but we do have to skip, so just read them
DS.packsize=read(tc,1,"int32");
read(tc,1,"int32"); %pad0
DS.status_packet_version=read(tc,1,"int8");
DS.SizeofBoolean=read(tc,1,"int8");
read(tc,6,"int8"); %pad 1-6
DS.StatusDataBlockNum=read(tc,1,"int64");
DS.NumDataBlockStoredInWaitToSendBuffer=read(tc,1,"int64");
DS.NumStatusBlockStoredInWaitToSendBuffer=read(tc,1,"int64");
read(tc,1,"int64"); %pad_7
DS.NumUnprocDataMessages=read(tc,1,"int32");
read(tc,3,"int32"); %pad_8-10
DS.DataAcqRunning=read(tc,1,"int8");  %there is no bool precision value, and even
                                      %if there were, we want to have 1 byte for certain
DS.DataStreaming=read(tc,1,"int8");
DS.PrimPMTBiasConnected=read(tc,1,"int8");
DS.PrimMainAcqBoardConnected=read(tc,1,"int8");
DS.PrimDDSDeviceConnected=read(tc,1,"int8");
DS.SecPMTBiasConnected=read(tc,1,"int8");
DS.SecMainAcqBoardConnected=read(tc,1,"int8");
DS.SecDDSDeviceConnected=read(tc,1,"int8");
DS.PrimPMTBiasVirtual=read(tc,1,"int8");
DS.PrimMainAcqBoardVirtual=read(tc,1,"int8");
DS.PrimDDSDeviceVirtual=read(tc,1,"int8");
DS.SecPMTBiasVirtual=read(tc,1,"int8");
DS.SecMainAcqBoardVirtual=read(tc,1,"int8");
DS.SecDDSDeviceVirtual=read(tc,1,"int8");
read(tc,1,"int8"); %pad_11
DS.AutoBiasInProgress=read(tc,1,"int8");
read(tc,2,"int8"); %pad_12 and 13
DS.AutoBiasOneInProgress=read(tc,1,"int8");
DS.AutoBiasAllInProgress=read(tc,1,"int8");
DS.DataClientIPAddress=read(tc,32,"uchar");
DS.DetectorOverLoadShutdown=read(tc,64,"int8");
DS.DetectorBias=read(tc,64,"int16");
read(tc,64,"int16"); %pad_2byteArray'


%for reference
%{
FROM STRUCTS 6.h
typedef struct {
	  unsigned __int32 packetsize; //set to the size of this structure, could be used to validate.
									//if zero, recieving program should assume invalid.
	  unsigned __int32 pad_0;

	  unsigned __int8 status_packet_version; //should be 6 at least as of now.
	  unsigned __int8 SizeofBoolean; //some c/c++ compiliers use different number of bytes for bool
	  unsigned __int8 pad_1;
	  unsigned __int8 pad_2;

	  unsigned __int8 pad_3;
	  unsigned __int8 pad_4;
	  unsigned __int8 pad_5;
	  unsigned __int8 pad_6;

	  unsigned __int64 StatusDataBlockNum; //unique and incrementing (by +1) number
						//if values skipped, likley buffer is backed up. Blocks
						//(or packets) will be disgarded without notice
						//(unlike data blocks).
	  unsigned __int64 NumDataBlockStoredInWaitToSendBuffer;
	  unsigned __int64 NumStatusBlockStoredInWaitToSendBuffer;
	  unsigned __int64 pad_7;
	  unsigned __int32 NumUnprocDataMessages;
	  unsigned __int32 pad_8;
	  unsigned __int32 pad_9;
	  unsigned __int32 pad_10;

	  bool DataAcqRunning;
	  bool DataStreaming;
	  bool PrimPMTBiasConnected;
	  bool PrimMainAcqBoardConnected;

	  bool PrimDDSDeviceConnected;
	  bool SecPMTBiasConnected;
	  bool SecMainAcqBoardConnected;
	  bool SecDDSDeviceConnected;

	  bool PrimPMTBiasVirtual;
	  bool PrimMainAcqBoardVirtual;
	  bool PrimDDSDeviceVirtual;
	  bool SecPMTBiasVirtual;

	  bool SecMainAcqBoardVirtual;
	  bool SecDDSDeviceVirtual;

	//added 2024 replaced pad_11
	  bool RP2040LEDCtrlVirtual;
	  bool AutoBiasInProgress;

	  bool pad12;

	  bool pad_13;
	  bool AutoBiasOneInProgress;
	  bool AutoBiasAllInProgress;

	  unsigned char DataClientIPAddress[32];
	  bool DetectorOverLoadShutdown[64];
	  __int16 DetectorBias[64];
	  __int16 pad_2byteArray[64];

   } STATUSDATA6;

%}

endfunction
