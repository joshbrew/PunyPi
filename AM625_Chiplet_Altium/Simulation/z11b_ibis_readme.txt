z11b IBIS Model
Die Rev "E"
8Gb DDR4 SDRAM IBIS Model
Rev 2.9.2: 2/27/2023

z11b.ibs is valid for Commercial Ambient Temperature Range 0C<=Tc<=95C
z11b_ait.ibs is valid for Industrial Ambient Temperature Range -40C<=Tc<=95C

Notes:
------

This IBIS model includes On Die Termination (ODT) characteristics.  ODT is
modeled through the use of [Submodel] power and ground clamp I-V curves that
add the termination characteristics to the regular power and ground clamp
characteristics when the I/O is functioning as an input.  ODT applies to the
DQ, DQS/DQS_n, TDQS/TDQS_n, DBI and DM signals.  Use the [Model Selector] to 
choose between 34, 40, 48, 60, 80, 120 or 240 ohm ODT settings.

The *_3200 models are valid for 1600 to 3200 Mbps speed grades.

Model syntax should be checked using the latest IBISCHK parser, Version 6.1.2 
or later.  Earlier versions may indicate erroneous Errors, Warnings or Cautions 
due to parser bugs.


Notes on Power Aware IBIS features:
-------------------------------------------

1. The on-die VDDQ-VSSQ decoupling circuit for DQ and DQS MUST be included 
   externally to the IBIS model.  Two options are available using the 
   following Spice subcircuits:

   a. z11b_ondie_decoupling_all.ckt - includes VDDQ-VSSQ decoupling for all 
      signals (full die) including DQ0-15, LDQS_t/c, UDQS_t/c, UDM and LDM. 
	  This circuit should be used for most simulation scenarios including x4
	  and x8 DQ options.

   b. z11b_ondie_decoupling_perdq.ckt - includes VDDQ-VSSQ decoupling for an 
      individual signal such as DQ0-15, LDQS_t/c, UDQS_t/c, UDM or LDM.  This 
      circuit is useful for correlation simulations comparing the IBIS model
	  and the Spice model for a single I/O.  22 instances of this subcircuit 
	  in parallel is equivalent to the z11b_ondie_decoupling_all.ckt circuit.

   Correct usage of these subcircuits requires adding them across the IBIS DQ 
   and DQS models' [Pullup Reference] and [Pulldown Reference] nodes (the die 
   power and ground pads inside of any package model).  Reference the .ckt 
   files for a Spice simulator example.

2. Due to the inclusion of [Composite Current] I-t waveforms, overclocking of 
   Models may be required, as the V-t and I-t waveforms are longer than the 
   bit period in some cases.

3. [Composite Current] and [ISSO *] data tables included for all DQ and DQS
   driver models.
   
4. If simulating the IBIS model in HSPICE, it is recommended to use 2016.03 or 
   newer version.
   

[Disclaimer]  This software code and all associated documentation, comments
              or other information (collectively "Software") is provided
              "AS IS" without warranty of any kind. MICRON TECHNOLOGY, INC.
              ("MTI") EXPRESSLY DISCLAIMS ALL WARRANTIES EXPRESS OR IMPLIED,
              INCLUDING BUT NOT LIMITED TO, NONINFRINGEMENT OF THIRD PARTY
              RIGHTS, AND ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR
              FITNESS FOR ANY PARTICULAR PURPOSE. MTI DOES NOT WARRANT THAT 
              THE SOFTWARE WILL MEET YOUR REQUIREMENTS, OR THAT THE 
              OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE. 
              FURTHERMORE, MTI DOES NOT MAKE ANY REPRESENTATIONS REGARDING
              THE USE OR THE RESULTS OF THE USE OF THE SOFTWARE IN TERMS OF
              ITS CORRECTNESS, ACCURACY, RELIABILITY, OR OTHERWISE. THE
              ENTIRE RISK ARISING OUT OF USE OR PERFORMANCE OF THE SOFTWARE
              REMAINS WITH YOU. IN NO EVENT SHALL MTI, ITS AFFILIATED
              COMPANIES OR THEIR SUPPLIERS BE LIABLE FOR ANY DIRECT,
              INDIRECT, CONSEQUENTIAL, INCIDENTAL, OR SPECIAL DAMAGES
              (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS,
              BUSINESS INTERRUPTION, OR LOSS OF INFORMATION) ARISING OUT OF
              YOUR USE OF OR INABILITY TO USE THE SOFTWARE, EVEN IF MTI HAS
              BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. Because some
              jurisdictions prohibit the exclusion or limitation of 
              liability for consequential or incidental damages, the above
              limitation may not apply to you.
 
[Copyright]   Copyright 2022 Micron Technology, Inc. All rights reserved.
