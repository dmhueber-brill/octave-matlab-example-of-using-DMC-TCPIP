## Author: dennis.hueber <dennis.hueber@DDH>
## Created: 2020-02-14

## updated to use tcpclient class 7 2026


%The data packets (not inlcuding the "data starts" and "data stops" text messages
%rom the server are binary data, the form of which is explained by the structures
%n strutcts 6.h.  This is meant mainly as an exmaple of parsign the data packet.

%I do not think this fucntion would be fast enough for continous data acquistion.
%Likely a .mex file might be usefull.

%Data is passed back in a structure, some of the elements are the members of the
%C structure the data packet is made from.  Some of the elements are matrixes
%containing data with the first dimension/row meaning cycle number.  By default
%the number of cycles in one packet is 8 in DMC

%Note the switch mode, number of cycles, and if frequency multiplexing is on,
%can all be changed.  The size and structure of the data packet can change based
%on these factors, but this has only been tested with DMC defaults.
%the number of detectors should not matter, the packet always assumes it might
%be 32, for the most part the packet size and structure leaves space for maximum
%values, but for number of data cycles.


function DS = tcpclient_DMC_readData (tc)

%We are going to skip the "pad" elements, but we do have to skip them, there are bytes
%of data corresponding to the "pad" elements of the structures, they are just not
%of interest at this time, and would clutter up the octave structure.

DS.start_msg=read(tc,64,"char");
DS.packetsize=read(tc,1,"int32");
DS.sizeof_header_data=read(tc,1,"int32");
DS.sizoef_one_cycle_of_data=read(tc,1,"int32");
read(tc,1,"int32"); %pad_1

DS.NumCyclesPerDataPacket=read(tc,1,"int16");
DS.packet_type=read(tc,1,"int16");
DS.version=read(tc,1,"int16");
DS.msg_buffer_id_number=read(tc,1,"int16");
read(tc,2,"int32"); %pad_2-3
DS.data_valid=read(tc,1,"int8");
read(tc,3,"int8"); %pad_4-6
DS.Counter=read(tc,8,"int32");
DS.timeproc=read(tc,1,"int32");
DS.data_block_num=read(tc,1,"int64");
DS.MsgToWin=read(tc,1,"int32");
DS.passCnt=read(tc,1,"int32");
DS.time=read(tc,1,"int32");
read(tc,1,"int32"); %pad_7
DS.missed_cycles=read(tc,1,"int16");
DS.unproc_msg=read(tc,1,"int16");
read(tc,2,"int16"); %pad_8-9

DS.volt_overflow_emc=read(tc,1024,"int8");

read(tc,32,"int16"); %pad10

%WE ARE NOW TO THE CYCLE DATA STRUCTURE.
%now we coudl read the cycle data in one buffer and sort it out later, but actually
%there is still some data in a header in the cycle data (jsut one copy now matter
%how many cycles, and some of the data is not doubles, whereas the biggest
%part is purely double precision floating point number in a big array.
%So if we wanted to pass the data to mex file or something we could do this.
%cycle_data_size=int32(DS.NumCyclesPerDataPacket)*DS.sizoef_one_cycle_of_data
%read(tc,cycle_data_size,"int8");
%but instead we will read the "header" part of the cycle data and put it in
%an array by cycle number called DS.CycleDataHeader. And but the data in a matrix
%called DS.SignalsCycleDataCycleData. Note that aux input data is int the header.

for i=1:DS.NumCyclesPerDataPacket
  DS.CycleDataHeader(i).CycleNumber1=read(tc,1,"int32"); %this should be 1, 2, 3 as we go throught the cycles, but for sake of the this example I will not check.
  DS.CycleDataHeader(i).MagicNumber1=read(tc,1,"int32"); %just a number unlikely to come up by chance "1234567890", so you might check it to be sure the decoding is working
  DS.CycleDataHeader(i).sw_mode=read(tc,1,"int16");%could be used to interpret the union of double arrays coming up, but we just assume for the sake of this example.
  read(tc,2,"int16"); %pad1 and pad2
  read(tc,128,"int16"); % rawWF, read but discard this, very do not always need it.
  read(tc,128,"double"); % sum_folded_rawWF, read but discard this, very do not always need it.
  DS.CycleDataAuxAnalInput(i,:)=double(read(tc,8,"double")); %put in a matrix with cyclenum as columns.
  DS.CycleDataHeader(i).DigAuxADCdata=read(tc,1,"int64");

  %The heart of the problem, the values representing the data form each channel pair.
  %For the sake of this example, just but it in a matrix with dimension 1 being the cycle number
  %and dim 2 being all binary value from one cycle.  The data is in a UNION in C++
  %thus the data cycles are alwasy the same size.  The largest size needed.  Switch-8
  %needs the largest size. It should be max_DATAPACKET6_a2d_chns * max_DATAPACKET6_8D_SW8_ext_mux_chns
  %times the number of values in a DCrealimage_2D structure (which is 5).  So there should be
  %enough data to desribe 32*32*5=5120 doubles. In switch-16 mode only the first 4608 have meaning, leaving
  %5120-4609=512 empty double at the end (if you are in switch-16 mode). 512 is also 32*16, since each
  %data structure for swtich-16 mode is one double shorter than for switch-8.
  %Here we will just read in all the data as double into a binary matrix. Column number (first dimension)
  %will be cycle number, second will be the data from one cycle.
  DS.CycleSignalData(i,:)=double(read(tc,5120,"double"));

  DS.CycleDataHeader(i).CycleNumber2=read(tc,1,"int32"); %should be a copy of cyclenumber1
  DS.CycleDataHeader(i).MagicNumber2=read(tc,1,"int32"); %another copy of 1234567890
endfor


endfunction

%FOR REFERENCE SOME THINGS FORM Structs 6.h


%{
#define max_DATAPACKET6_a2d_chns 32
#define max_DATAPACKET6_a2d_counters 8
#define max_DATAPACKET6_a2d_chns 32
#define max_DATAPACKET6_ext_mux_chns 32
#define max_DATAPACKET6_aqs_per_wf 128
#define max_DATAPACKET6_auxadc_chns 8
#define max_DATAPACKET6_4D_SW16_ext_mux_chns 16
#define max_DATAPACKET6_8D_SW8_ext_mux_chns

template< int T=max_DATAPACKET6_ext_mux_cycles_per_message>
struct DATAPACKET6_TEMPLATE {
   HEADERDATA6 Header; //header most be first, as sometimes in streams
						//the actual size of the array below.
   CYCLEDATA6 ExtMuxCycleNum[T];
};



//A structure to store information that is passed with each block of data, but
//is not repeated with each cycle of the external mux
typedef struct {
//
//Version and packet_type information section.
//
	  char start_msg[64];
	  unsigned __int32 packetsize;
	  unsigned __int32 sizeof_header_data;
	  unsigned __int32 sizoef_one_cycle_of_data;
	  unsigned __int32 pad1;

	  unsigned __int16  NumCyclesPerDataPacket;//number of data acquisition (or
					//source external mux cycles in each packet.
	  unsigned __int16 packet_type;//always = 1 for this packet_type,
								//also passed in wparam, used by 16-bit driver.
	  unsigned __int16 version;  //driver version currently always = 1.
	  unsigned __int16 msg_buffer_id_number; //a number associated with this message
					  //used internally to indicate the buffer region used to store
					  //the data before transmission via TCPIP.

	  unsigned __int32 pad2;
	  unsigned __int32 pad3;


	  bool data_valid;//Presently always true (reserved for future use),
						 // In future false will be used for "bad" data.

	  bool pad4;
	  bool pad5;
	  bool pad6;

//
//Debug information section. (Some of this information not sent if debug
// information is turned off.)
//
	  unsigned __int32 Counter[max_DATAPACKET6_a2d_counters];//Value of A2D's counters when data transfer
							//started. [counter number]
	  unsigned __int32 timeproc;//This is the time in microseconds between detecting
					   //when the buffer was full and posting the DataReady
					  //message (buffer processing time).

	  unsigned __int64 data_block_num; //number that increases with each data blcok transferrred from the data acquistion system.

	  //Information useful for testing and debugging.
	  unsigned __int32 MsgToWin;//32 bit integer equal to the window to which this
						//message was sent, or would have been sent if a
					 //"monitor" program had not Overriden it. This parameter
					 //can be ignored in must cases, this is a 16 bit HWND
					 //if it this packet is sent from a 16-bit driver and
					 //a 32-bit HWND if sent from a 32-bit driver.
	  unsigned __int32 passCnt; //Number of times the timer callback function has
					  //been called

	  unsigned __int32 time;//Time tag, time since instance of processor was started.
						//in us. This time is recorded just before posting the
						//the message.
	  unsigned __int32 pad7;

	  //Information about the state of the machine.
	  unsigned __int16 missed_cycles; //Number of these messages missed sinde the
						//current instances created, of ResetMissed called.
	  unsigned __int16 unproc_msg;//Number of "_DataReady" messages posted but not
							//responded to, when this message was posted.
						//(Should be 0-1 unless program is too slow.)
	  unsigned __int16 pad8;
	  unsigned __int16 pad9;

	  unsigned __int8 volt_overflow_emc[max_DATAPACKET6_a2d_chns][max_DATAPACKET6_ext_mux_chns];
							//Individual emc boltage overflow flags, true (1) if any A2D values
							//were equal to the limits of the A2D range.
					   //3 if 95% of values within max limits.

	  unsigned __int16 pad10[max_DATAPACKET6_a2d_chns];

   } HEADERDATA6;


//A structure for the data taken with each cycle of the external mux (light
//source switching cycle).  Not that DCrealimage_4 is defined elsewhere
/*
typedef struct
   {
   double DC;
   double real[4];
   double imag[4];
   } DCrealimage_4D;

typedef struct
   {
   double DC;
   double real[2];
   double imag[2];
   } DCrealimage_2D;

*/


typedef union
	{
	DCrealimage_8D view_8D_sw8[max_DATAPACKET6_a2d_chns][max_DATAPACKET6_8D_SW8_ext_mux_chns];
	DCrealimage_4D view_4D_sw16[max_DATAPACKET6_a2d_chns][max_DATAPACKET6_4D_SW16_ext_mux_chns];
	DCrealimage_2D view_2D_sw32[max_DATAPACKET6_a2d_chns][max_DATAPACKET6_2D_SW32_ext_mux_chns];
	}CC_WFDATA_UNION;


typedef struct {
	  unsigned __int32 CycleNumber1;
	  unsigned __int32 MagicNumber1;  //7 lsb should be 1234567890, high byte is copy of cycle number
	  __int16 sw_mode; // used to interpret data union below
	  __int16 pad1;
	  __int16 pad2;
	  //Raw waveform data the ADC and Mux channels for the raw data are determined in USER_SET6
	  __int16 rawWF[max_DATAPACKET6_aqs_per_wf]; //completely raw data
	  double sum_folded_rawWF[max_DATAPACKET6_aqs_per_wf]; //folded raw data from

	  //Aux data
	  double AnalAuxADCdata[max_DATAPACKET6_auxadc_chns];
	  __int64 DigAuxADCdata;

	  //Main ADC data
	  CC_WFDATA_UNION cc_wfdata;

	  unsigned __int32 CycleNumber2;
	  unsigned __int32 MagicNumber2;  //7 lsb should be 1234567890, high byte is copy of cycle number
	 } CYCLEDATA6;

%}

