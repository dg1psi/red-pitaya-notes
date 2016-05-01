# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_0 {
  DIN_WIDTH 8 DIN_FROM 0 DIN_TO 0 DOUT_WIDTH 1
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_1 {
  DIN_WIDTH 160 DIN_FROM 15 DIN_TO 0 DOUT_WIDTH 16
}

# Create axis_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 2
} {
  m_axis_aclk /ps_0/FCLK_CLK0
  m_axis_aresetn /rst_0/peripheral_aresetn
}

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 2
  M_TDATA_NUM_BYTES 2
  NUM_MI 4
  M00_TDATA_REMAP {tdata[15:0]}
  M01_TDATA_REMAP {tdata[15:0]}
  M02_TDATA_REMAP {tdata[15:0]}
  M03_TDATA_REMAP {tdata[15:0]}
} {
  S_AXIS fifo_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

for {set i 0} {$i <= 3} {incr i} {

  # Create xlslice
  cell xilinx.com:ip:xlslice:1.0 slice_[expr $i + 2] {
    DIN_WIDTH 160 DIN_FROM [expr 32 * $i + 63] DIN_TO [expr 32 * $i + 32] DOUT_WIDTH 32
  }

  # Create axis_constant
  cell pavel-demin:user:axis_constant:1.0 phase_$i {
    AXIS_TDATA_WIDTH 32
  } {
    cfg_data slice_[expr $i + 2]/Dout
    aclk /ps_0/FCLK_CLK0
  }

  # Create dds_compiler
  cell xilinx.com:ip:dds_compiler:6.0 dds_$i {
    DDS_CLOCK_RATE 125
    SPURIOUS_FREE_DYNAMIC_RANGE 138
    FREQUENCY_RESOLUTION 0.2
    PHASE_INCREMENT Streaming
    HAS_TREADY true
    HAS_PHASE_OUT false
    PHASE_WIDTH 30
    OUTPUT_WIDTH 24
    DSP48_USE Minimal
    NEGATIVE_SINE true
  } {
    S_AXIS_PHASE phase_$i/M_AXIS
    aclk /ps_0/FCLK_CLK0
  }

  # Create axis_lfsr
  cell pavel-demin:user:axis_lfsr:1.0 lfsr_$i {} {
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

  # Create cmpy
  cell xilinx.com:ip:cmpy:6.0 mult_$i {
    FLOWCONTROL Blocking
    APORTWIDTH.VALUE_SRC USER
    BPORTWIDTH.VALUE_SRC USER
    APORTWIDTH 14
    BPORTWIDTH 24
    ROUNDMODE Random_Rounding
    OUTPUTWIDTH 25
  } {
    S_AXIS_A bcast_0/M0${i}_AXIS
    S_AXIS_B dds_$i/M_AXIS_DATA
    S_AXIS_CTRL lfsr_$i/M_AXIS
    aclk /ps_0/FCLK_CLK0
  }

  # Create axis_broadcaster
  cell xilinx.com:ip:axis_broadcaster:1.1 bcast_[expr $i + 1] {
    S_TDATA_NUM_BYTES.VALUE_SRC USER
    M_TDATA_NUM_BYTES.VALUE_SRC USER
    S_TDATA_NUM_BYTES 8
    M_TDATA_NUM_BYTES 3
    M00_TDATA_REMAP {tdata[23:0]}
    M01_TDATA_REMAP {tdata[55:32]}
  } {
    S_AXIS mult_$i/M_AXIS_DOUT
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

}

for {set i 0} {$i <= 7} {incr i} {

  # Create axis_variable
  cell pavel-demin:user:axis_variable:1.0 rate_$i {
    AXIS_TDATA_WIDTH 16
  } {
    cfg_data slice_1/Dout
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

  # Create cic_compiler
  cell xilinx.com:ip:cic_compiler:4.0 cic_$i {
    INPUT_DATA_WIDTH.VALUE_SRC USER
    FILTER_TYPE Decimation
    NUMBER_OF_STAGES 6
    SAMPLE_RATE_CHANGES Programmable
    MINIMUM_RATE 125
    MAXIMUM_RATE 8192
    FIXED_OR_INITIAL_RATE 500
    INPUT_SAMPLE_FREQUENCY 125
    CLOCK_FREQUENCY 125
    INPUT_DATA_WIDTH 24
    QUANTIZATION Truncation
    OUTPUT_DATA_WIDTH 24
    USE_XTREME_DSP_SLICE false
    HAS_DOUT_TREADY true
    HAS_ARESETN true
  } {
    S_AXIS_DATA bcast_[expr $i / 2 + 1]/M0[expr $i % 2]_AXIS
    S_AXIS_CONFIG rate_$i/M_AXIS
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

}

# Create axis_combiner
cell  xilinx.com:ip:axis_combiner:1.1 comb_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 3
  NUM_SI 8
} {
  S00_AXIS cic_0/M_AXIS_DATA
  S01_AXIS cic_1/M_AXIS_DATA
  S02_AXIS cic_2/M_AXIS_DATA
  S03_AXIS cic_3/M_AXIS_DATA
  S04_AXIS cic_4/M_AXIS_DATA
  S05_AXIS cic_5/M_AXIS_DATA
  S06_AXIS cic_6/M_AXIS_DATA
  S07_AXIS cic_7/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 24
  M_TDATA_NUM_BYTES 3
} {
  S_AXIS comb_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_0 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 24
  COEFFICIENTVECTOR {1.1961245066e-08, 1.2656108167e-08, 1.3309353571e-08, 1.3941028874e-08, 1.4577279025e-08, 1.5250460331e-08, 1.5999119963e-08, 1.6867826841e-08, 1.7906841259e-08, 1.9171612419e-08, 2.0722095181e-08, 2.2621879857e-08, 2.4937131678e-08, 2.7735339695e-08, 3.1083878269e-08, 3.5048387923e-08, 3.9690986153e-08, 4.5068322788e-08, 5.1229498494e-08, 5.8213869173e-08, 6.6048762982e-08, 7.4747140729e-08, 8.4305234107e-08, 9.4700199781e-08, 1.0588783054e-07, 1.1780036751e-07, 1.3034445969e-07, 1.4339931898e-07, 1.5681511974e-07, 1.7041169269e-07, 1.8397756236e-07, 1.9726937647e-07, 2.1001177348e-07, 2.2189773177e-07, 2.3258944045e-07, 2.4171972680e-07, 2.4889407015e-07, 2.5369322559e-07, 2.5567647341e-07, 2.5438550268e-07, 2.4934892788e-07, 2.4008742888e-07, 2.2611949400e-07, 2.0696773561e-07, 1.8216573725e-07, 1.5126537985e-07, 1.1384458395e-07, 6.9515393959e-08, 1.7932319579e-08, -4.1199160230e-08, -1.0811403513e-07, -1.8297925609e-07, -2.6588540362e-07, -3.5683865869e-07, -4.5575320867e-07, -5.6244422446e-07, -6.7662154650e-07, -7.9788421816e-07, -9.2571600254e-07, -1.0594820156e-06, -1.1984266018e-06, -1.3416725718e-06, -1.4882219093e-06, -1.6369580433e-06, -1.7866497683e-06, -1.9359568745e-06, -2.0834375358e-06, -2.2275574799e-06, -2.3667009437e-06, -2.4991833931e-06, -2.6232659609e-06, -2.7371715321e-06, -2.8391023766e-06, -2.9272592053e-06, -2.9998614945e-06, -3.0551689028e-06, -3.0915035709e-06, -3.1072730774e-06, -3.1009937957e-06, -3.0713143764e-06, -3.0170390631e-06, -2.9371505298e-06, -2.8308319185e-06, -2.6974877428e-06, -2.5367633207e-06, -2.3485623953e-06, -2.1330626091e-06, -1.8907284997e-06, -1.6223217031e-06, -1.3289080634e-06, -1.0118613734e-06, -6.7286349537e-07, -3.1390064680e-07, 6.2744330652e-08, 4.5450385566e-07, 8.5854173791e-07, 1.2717735970e-06, 1.6908915579e-06, 2.1123931561e-06, 2.5326143242e-06, 2.9477662746e-06, 3.3539760273e-06, 3.7473302740e-06, 4.1239222030e-06, 4.4799008547e-06, 4.8115225143e-06, 5.1152035966e-06, 5.3875744241e-06, 5.6255332554e-06, 5.8262998780e-06, 5.9874680465e-06, 6.1070560204e-06, 6.1835544346e-06, 6.2159707293e-06, 6.2038693619e-06, 6.1474070329e-06, 6.0473621801e-06, 5.9051580216e-06, 5.7228784708e-06, 5.5032763002e-06, 5.2497729887e-06, 4.9664497653e-06, 4.6580294439e-06, 4.3298487341e-06, 3.9878208223e-06, 3.6383881208e-06, 3.2884652057e-06, 2.9453720871e-06, 2.6167580855e-06, 2.3105167192e-06, 2.0346921477e-06, 1.7973778467e-06, 1.6066083302e-06, 1.4702448653e-06, 1.3958562538e-06, 1.3905958769e-06, 1.4610763121e-06, 1.6132429361e-06, 1.8522480178e-06, 2.1823268856e-06, 2.6066778149e-06, 3.1273473287e-06, 3.7451226329e-06, 4.4594329156e-06, 5.2682612301e-06, 6.1680686450e-06, 7.1537322944e-06, 8.2184988774e-06, 9.3539550616e-06, 1.0550016118e-05, 1.1794933972e-05, 1.3075325685e-05, 1.4376223195e-05, 1.5681144940e-05, 1.6972189756e-05, 1.8230153205e-05, 1.9434666227e-05, 2.0564355758e-05, 2.1597026644e-05, 2.2509863950e-05, 2.3279654423e-05, 2.3883025624e-05, 2.4296700925e-05, 2.4497768329e-05, 2.4463960766e-05, 2.4173945299e-05, 2.3607618414e-05, 2.2746404378e-05, 2.1573553434e-05, 2.0074436473e-05, 1.8236832669e-05, 1.6051206476e-05, 1.3510970340e-05, 1.0612729430e-05, 7.3565047648e-06, 3.7459311219e-06, -2.1157373450e-07, -4.5046718270e-06, -9.1180028640e-06, -1.4032120137e-05, -1.9223467001e-05, -2.4664396187e-05, -3.0323233834e-05, -3.6164389688e-05, -4.2148514504e-05, -4.8232705175e-05, -5.4370757623e-05, -6.0513466940e-05, -6.6608973738e-05, -7.2603155076e-05, -7.8440057785e-05, -8.4062371427e-05, -8.9411937561e-05, -9.4430291431e-05, -9.9059231671e-05, -1.0324141308e-04, -1.0692095708e-04, -1.1004407399e-04, -1.1255969092e-04, -1.1442007866e-04, -1.1558147072e-04, -1.1600466749e-04, -1.1565561822e-04, -1.1450597358e-04, -1.1253360148e-04, -1.0972305893e-04, -1.0606601291e-04, -1.0156160349e-04, -9.6216742676e-05, -9.0046343017e-05, -8.3073470457e-05, -7.5329416481e-05, -6.6853685336e-05, -5.7693892821e-05, -4.7905573966e-05, -3.7551897816e-05, -2.6703288469e-05, -1.5436952505e-05, -3.8363139815e-06, 8.0096407494e-06, 2.0007105101e-05, 3.2058276750e-05, 4.4062259067e-05, 5.5916032885e-05, 6.7515490953e-05, 7.8756526415e-05, 8.9536165679e-05, 9.9753735148e-05, 1.0931205045e-04, 1.1811861606e-04, 1.2608682262e-04, 1.3313712860e-04, 1.3919821272e-04, 1.4420808314e-04, 1.4811512926e-04, 1.5087910214e-04, 1.5247200951e-04, 1.5287891179e-04, 1.5209860590e-04, 1.5014418435e-04, 1.4704345786e-04, 1.4283923068e-04, 1.3758941891e-04, 1.3136700327e-04, 1.2425980938e-04, 1.1637010987e-04, 1.0781404442e-04, 9.8720855572e-05, 8.9231940053e-05, 7.9499717050e-05, 6.9686317232e-05, 5.9962098023e-05, 5.0503992897e-05, 4.1493704457e-05, 3.3115753143e-05, 2.5555395434e-05, 1.8996427397e-05, 1.3618891281e-05, 9.5967046990e-06, 7.0952335593e-06, 6.2688314555e-06, 7.2583695702e-06, 1.0188782321e-05, 1.5166654945e-05, 2.2277879967e-05, 3.1585410007e-05, 4.3127134636e-05, 5.6913909010e-05, 7.2927761717e-05, 9.1120308728e-05, 1.1141139952e-04, 1.3368802032e-04, 1.5780347798e-04, 1.8357688632e-04, 2.1079297497e-04, 2.3920223810e-04, 2.6852143849e-04, 2.9843447925e-04, 3.2859365272e-04, 3.5862127298e-04, 3.8811169485e-04, 4.1663371924e-04, 4.4373338044e-04, 4.6893710791e-04, 4.9175525092e-04, 5.1168595069e-04, 5.2821934111e-04, 5.4084205492e-04, 5.4904200902e-04, 5.5231343861e-04, 5.5016214675e-04, 5.4211093240e-04, 5.2770515714e-04, 5.0651840800e-04, 4.7815821114e-04, 4.4227174930e-04, 3.9855153363e-04, 3.4674097954e-04, 2.8663983471e-04, 2.1810940719e-04, 1.4107754080e-04, 5.5543285854e-05, -3.8418786621e-05, -1.4065467735e-04, -2.5092750685e-04, -3.6891456558e-04, -4.9420491034e-04, -6.2629754784e-04, -7.6460024308e-04, -9.0842898607e-04, -1.0570081464e-03, -1.2094713400e-03, -1.3648630285e-03, -1.5221408641e-03, -1.6801787908e-03, -1.8377709026e-03, -1.9936360574e-03, -2.1464232367e-03, -2.2947176355e-03, -2.4370474604e-03, -2.5718914099e-03, -2.6976867996e-03, -2.8128382946e-03, -2.9157272026e-03, -3.0047212747e-03, -3.0781849584e-03, -3.1344900397e-03, -3.1720266076e-03, -3.1892142704e-03, -3.1845135487e-03, -3.1564373671e-03, -3.1035625641e-03, -3.0245413366e-03, -2.9181125367e-03, -2.7831127328e-03, -2.6184869521e-03, -2.4232990185e-03, -2.1967414023e-03, -1.9381444998e-03, -1.6469852638e-03, -1.3228951082e-03, -9.6566701483e-04, -5.7526177425e-04, -1.5181329794e-04, 3.0436705551e-04, 7.9278719108e-04, 1.3127720694e-03, 1.8634626169e-03, 2.4438157851e-03, 3.0526057782e-03, 3.6884264660e-03, 4.3496949844e-03, 5.0346565220e-03, 5.7413902800e-03, 6.4678165856e-03, 7.2117051287e-03, 7.9706842849e-03, 8.7422514784e-03, 9.5237845309e-03, 1.0312553935e-02, 1.1105735981e-02, 1.1900426663e-02, 1.2693656283e-02, 1.3482404659e-02, 1.4263616846e-02, 1.5034219280e-02, 1.5791136222e-02, 1.6531306423e-02, 1.7251699879e-02, 1.7949334580e-02, 1.8621293136e-02, 1.9264739177e-02, 1.9876933407e-02, 2.0455249216e-02, 2.0997187730e-02, 2.1500392215e-02, 2.1962661719e-02, 2.2381963874e-02, 2.2756446754e-02, 2.3084449725e-02, 2.3364513198e-02, 2.3595387227e-02, 2.3776038880e-02, 2.3905658354e-02, 2.3983663763e-02, 2.4009704590e-02, 2.3983663763e-02, 2.3905658354e-02, 2.3776038880e-02, 2.3595387227e-02, 2.3364513198e-02, 2.3084449725e-02, 2.2756446754e-02, 2.2381963874e-02, 2.1962661719e-02, 2.1500392215e-02, 2.0997187730e-02, 2.0455249216e-02, 1.9876933407e-02, 1.9264739177e-02, 1.8621293136e-02, 1.7949334580e-02, 1.7251699879e-02, 1.6531306423e-02, 1.5791136222e-02, 1.5034219280e-02, 1.4263616846e-02, 1.3482404659e-02, 1.2693656283e-02, 1.1900426663e-02, 1.1105735981e-02, 1.0312553935e-02, 9.5237845309e-03, 8.7422514784e-03, 7.9706842849e-03, 7.2117051287e-03, 6.4678165856e-03, 5.7413902800e-03, 5.0346565220e-03, 4.3496949844e-03, 3.6884264660e-03, 3.0526057782e-03, 2.4438157851e-03, 1.8634626169e-03, 1.3127720694e-03, 7.9278719108e-04, 3.0436705551e-04, -1.5181329794e-04, -5.7526177425e-04, -9.6566701483e-04, -1.3228951082e-03, -1.6469852638e-03, -1.9381444998e-03, -2.1967414023e-03, -2.4232990185e-03, -2.6184869521e-03, -2.7831127328e-03, -2.9181125367e-03, -3.0245413366e-03, -3.1035625641e-03, -3.1564373671e-03, -3.1845135487e-03, -3.1892142704e-03, -3.1720266076e-03, -3.1344900397e-03, -3.0781849584e-03, -3.0047212747e-03, -2.9157272026e-03, -2.8128382946e-03, -2.6976867996e-03, -2.5718914099e-03, -2.4370474604e-03, -2.2947176355e-03, -2.1464232367e-03, -1.9936360574e-03, -1.8377709026e-03, -1.6801787908e-03, -1.5221408641e-03, -1.3648630285e-03, -1.2094713400e-03, -1.0570081464e-03, -9.0842898607e-04, -7.6460024308e-04, -6.2629754784e-04, -4.9420491034e-04, -3.6891456558e-04, -2.5092750685e-04, -1.4065467735e-04, -3.8418786621e-05, 5.5543285854e-05, 1.4107754080e-04, 2.1810940719e-04, 2.8663983471e-04, 3.4674097954e-04, 3.9855153363e-04, 4.4227174930e-04, 4.7815821114e-04, 5.0651840800e-04, 5.2770515714e-04, 5.4211093240e-04, 5.5016214675e-04, 5.5231343861e-04, 5.4904200902e-04, 5.4084205492e-04, 5.2821934111e-04, 5.1168595069e-04, 4.9175525092e-04, 4.6893710791e-04, 4.4373338044e-04, 4.1663371924e-04, 3.8811169485e-04, 3.5862127298e-04, 3.2859365272e-04, 2.9843447925e-04, 2.6852143849e-04, 2.3920223810e-04, 2.1079297497e-04, 1.8357688632e-04, 1.5780347798e-04, 1.3368802032e-04, 1.1141139952e-04, 9.1120308728e-05, 7.2927761717e-05, 5.6913909010e-05, 4.3127134636e-05, 3.1585410007e-05, 2.2277879967e-05, 1.5166654945e-05, 1.0188782321e-05, 7.2583695702e-06, 6.2688314555e-06, 7.0952335593e-06, 9.5967046990e-06, 1.3618891281e-05, 1.8996427397e-05, 2.5555395434e-05, 3.3115753143e-05, 4.1493704457e-05, 5.0503992897e-05, 5.9962098023e-05, 6.9686317232e-05, 7.9499717050e-05, 8.9231940053e-05, 9.8720855572e-05, 1.0781404442e-04, 1.1637010987e-04, 1.2425980938e-04, 1.3136700327e-04, 1.3758941891e-04, 1.4283923068e-04, 1.4704345786e-04, 1.5014418435e-04, 1.5209860590e-04, 1.5287891179e-04, 1.5247200951e-04, 1.5087910214e-04, 1.4811512926e-04, 1.4420808314e-04, 1.3919821272e-04, 1.3313712860e-04, 1.2608682262e-04, 1.1811861606e-04, 1.0931205045e-04, 9.9753735148e-05, 8.9536165679e-05, 7.8756526415e-05, 6.7515490953e-05, 5.5916032885e-05, 4.4062259067e-05, 3.2058276750e-05, 2.0007105101e-05, 8.0096407494e-06, -3.8363139815e-06, -1.5436952505e-05, -2.6703288469e-05, -3.7551897816e-05, -4.7905573966e-05, -5.7693892821e-05, -6.6853685336e-05, -7.5329416481e-05, -8.3073470457e-05, -9.0046343017e-05, -9.6216742676e-05, -1.0156160349e-04, -1.0606601291e-04, -1.0972305893e-04, -1.1253360148e-04, -1.1450597358e-04, -1.1565561822e-04, -1.1600466749e-04, -1.1558147072e-04, -1.1442007866e-04, -1.1255969092e-04, -1.1004407399e-04, -1.0692095708e-04, -1.0324141308e-04, -9.9059231671e-05, -9.4430291431e-05, -8.9411937561e-05, -8.4062371427e-05, -7.8440057785e-05, -7.2603155076e-05, -6.6608973738e-05, -6.0513466940e-05, -5.4370757623e-05, -4.8232705175e-05, -4.2148514504e-05, -3.6164389688e-05, -3.0323233834e-05, -2.4664396187e-05, -1.9223467001e-05, -1.4032120137e-05, -9.1180028640e-06, -4.5046718270e-06, -2.1157373450e-07, 3.7459311219e-06, 7.3565047648e-06, 1.0612729430e-05, 1.3510970340e-05, 1.6051206476e-05, 1.8236832669e-05, 2.0074436473e-05, 2.1573553434e-05, 2.2746404378e-05, 2.3607618414e-05, 2.4173945299e-05, 2.4463960766e-05, 2.4497768329e-05, 2.4296700925e-05, 2.3883025624e-05, 2.3279654423e-05, 2.2509863950e-05, 2.1597026644e-05, 2.0564355758e-05, 1.9434666227e-05, 1.8230153205e-05, 1.6972189756e-05, 1.5681144940e-05, 1.4376223195e-05, 1.3075325685e-05, 1.1794933972e-05, 1.0550016118e-05, 9.3539550616e-06, 8.2184988774e-06, 7.1537322944e-06, 6.1680686450e-06, 5.2682612301e-06, 4.4594329156e-06, 3.7451226329e-06, 3.1273473287e-06, 2.6066778149e-06, 2.1823268856e-06, 1.8522480178e-06, 1.6132429361e-06, 1.4610763121e-06, 1.3905958769e-06, 1.3958562538e-06, 1.4702448653e-06, 1.6066083302e-06, 1.7973778467e-06, 2.0346921477e-06, 2.3105167192e-06, 2.6167580855e-06, 2.9453720871e-06, 3.2884652057e-06, 3.6383881208e-06, 3.9878208223e-06, 4.3298487341e-06, 4.6580294439e-06, 4.9664497653e-06, 5.2497729887e-06, 5.5032763002e-06, 5.7228784708e-06, 5.9051580216e-06, 6.0473621801e-06, 6.1474070329e-06, 6.2038693619e-06, 6.2159707293e-06, 6.1835544346e-06, 6.1070560204e-06, 5.9874680465e-06, 5.8262998780e-06, 5.6255332554e-06, 5.3875744241e-06, 5.1152035966e-06, 4.8115225143e-06, 4.4799008547e-06, 4.1239222030e-06, 3.7473302740e-06, 3.3539760273e-06, 2.9477662746e-06, 2.5326143242e-06, 2.1123931561e-06, 1.6908915579e-06, 1.2717735970e-06, 8.5854173791e-07, 4.5450385566e-07, 6.2744330652e-08, -3.1390064680e-07, -6.7286349537e-07, -1.0118613734e-06, -1.3289080634e-06, -1.6223217031e-06, -1.8907284997e-06, -2.1330626091e-06, -2.3485623953e-06, -2.5367633207e-06, -2.6974877428e-06, -2.8308319185e-06, -2.9371505298e-06, -3.0170390631e-06, -3.0713143764e-06, -3.1009937957e-06, -3.1072730774e-06, -3.0915035709e-06, -3.0551689028e-06, -2.9998614945e-06, -2.9272592053e-06, -2.8391023766e-06, -2.7371715321e-06, -2.6232659609e-06, -2.4991833931e-06, -2.3667009437e-06, -2.2275574799e-06, -2.0834375358e-06, -1.9359568745e-06, -1.7866497683e-06, -1.6369580433e-06, -1.4882219093e-06, -1.3416725718e-06, -1.1984266018e-06, -1.0594820156e-06, -9.2571600254e-07, -7.9788421816e-07, -6.7662154650e-07, -5.6244422446e-07, -4.5575320867e-07, -3.5683865869e-07, -2.6588540362e-07, -1.8297925609e-07, -1.0811403513e-07, -4.1199160230e-08, 1.7932319579e-08, 6.9515393959e-08, 1.1384458395e-07, 1.5126537985e-07, 1.8216573725e-07, 2.0696773561e-07, 2.2611949400e-07, 2.4008742888e-07, 2.4934892788e-07, 2.5438550268e-07, 2.5567647341e-07, 2.5369322559e-07, 2.4889407015e-07, 2.4171972680e-07, 2.3258944045e-07, 2.2189773177e-07, 2.1001177348e-07, 1.9726937647e-07, 1.8397756236e-07, 1.7041169269e-07, 1.5681511974e-07, 1.4339931898e-07, 1.3034445969e-07, 1.1780036751e-07, 1.0588783054e-07, 9.4700199781e-08, 8.4305234107e-08, 7.4747140729e-08, 6.6048762982e-08, 5.8213869173e-08, 5.1229498494e-08, 4.5068322788e-08, 3.9690986153e-08, 3.5048387923e-08, 3.1083878269e-08, 2.7735339695e-08, 2.4937131678e-08, 2.2621879857e-08, 2.0722095181e-08, 1.9171612419e-08, 1.7906841259e-08, 1.6867826841e-08, 1.5999119963e-08, 1.5250460331e-08, 1.4577279025e-08, 1.3941028874e-08, 1.3309353571e-08, 1.2656108167e-08, 1.1961245066e-08}
  COEFFICIENT_WIDTH 24
  QUANTIZATION Maximize_Dynamic_Range
  BESTPRECISION true
  FILTER_TYPE Decimation
  RATE_CHANGE_TYPE Fixed_Fractional
  INTERPOLATION_RATE 24
  DECIMATION_RATE 25
  NUMBER_CHANNELS 8
  NUMBER_PATHS 1
  SAMPLE_FREQUENCY 1.0
  CLOCK_FREQUENCY 125
  OUTPUT_ROUNDING_MODE Convergent_Rounding_to_Even
  OUTPUT_WIDTH 25
  M_DATA_HAS_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA conv_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 subset_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 3
  TDATA_REMAP {tdata[23:0]}
} {
  S_AXIS fir_0/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_1 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 24
  COEFFICIENTVECTOR {-1.5065458369e-08, 4.0943728857e-09, 9.7221813080e-09, -3.2389062140e-08, -1.4704207189e-07, -3.2339733379e-07, -4.9277029618e-07, -5.2462312568e-07, -2.5263380040e-07, 4.6611149321e-07, 1.6696422638e-06, 3.2128528431e-06, 4.7273710273e-06, 5.6526738863e-06, 5.3555081537e-06, 3.3260010889e-06, -5.9508829463e-07, -6.0310219044e-06, -1.2007021855e-05, -1.7073033543e-05, -1.9624018286e-05, -1.8362675826e-05, -1.2782678242e-05, -3.5097068354e-06, 7.6550917123e-06, 1.8079025318e-05, 2.5003695245e-05, 2.6451323853e-05, 2.2057285357e-05, 1.3511349514e-05, 4.3497378821e-06, -9.9289147393e-07, 1.2796435697e-06, 1.2600734569e-05, 3.0703495559e-05, 4.9260059297e-05, 5.8902344885e-05, 4.9657448885e-05, 1.4354724204e-05, -4.7883035588e-05, -1.2920864781e-04, -2.1276404771e-04, -2.7519275892e-04, -2.9186378215e-04, -2.4383650036e-04, -1.2482612377e-04, 5.3957883204e-05, 2.6302891961e-04, 4.5898169499e-04, 5.9372618228e-04, 6.2679259286e-04, 5.3762021386e-04, 3.3416432513e-04, 5.4594819494e-05, -2.3962513534e-04, -4.7866644375e-04, -6.0408034613e-04, -5.8809954355e-04, -4.4637889169e-04, -2.3892619508e-04, -5.6618781674e-05, 5.3356146002e-06, -1.1870495686e-04, -4.3275426166e-04, -8.5960465448e-04, -1.2429139941e-03, -1.3757490070e-03, -1.0536102009e-03, -1.4236718113e-04, 1.3549428330e-03, 3.2518613288e-03, 5.1709688845e-03, 6.5868955023e-03, 6.9210628960e-03, 5.6763883194e-03, 2.5878461347e-03, -2.2437481048e-03, -8.2694222584e-03, -1.4490042865e-02, -1.9550023545e-02, -2.1923295848e-02, -2.0167530662e-02, -1.3204825143e-02, -5.7637574971e-04, 1.7381898628e-02, 3.9485221516e-02, 6.3789404308e-02, 8.7819539431e-02, 1.0890632987e-01, 1.2457600210e-01, 1.3292704532e-01, 1.3292704532e-01, 1.2457600210e-01, 1.0890632987e-01, 8.7819539431e-02, 6.3789404308e-02, 3.9485221516e-02, 1.7381898628e-02, -5.7637574971e-04, -1.3204825143e-02, -2.0167530662e-02, -2.1923295848e-02, -1.9550023545e-02, -1.4490042865e-02, -8.2694222584e-03, -2.2437481048e-03, 2.5878461347e-03, 5.6763883194e-03, 6.9210628960e-03, 6.5868955023e-03, 5.1709688845e-03, 3.2518613288e-03, 1.3549428330e-03, -1.4236718113e-04, -1.0536102009e-03, -1.3757490070e-03, -1.2429139941e-03, -8.5960465448e-04, -4.3275426166e-04, -1.1870495686e-04, 5.3356146002e-06, -5.6618781674e-05, -2.3892619508e-04, -4.4637889169e-04, -5.8809954355e-04, -6.0408034613e-04, -4.7866644375e-04, -2.3962513534e-04, 5.4594819494e-05, 3.3416432513e-04, 5.3762021386e-04, 6.2679259286e-04, 5.9372618228e-04, 4.5898169499e-04, 2.6302891961e-04, 5.3957883204e-05, -1.2482612377e-04, -2.4383650036e-04, -2.9186378215e-04, -2.7519275892e-04, -2.1276404771e-04, -1.2920864781e-04, -4.7883035588e-05, 1.4354724204e-05, 4.9657448885e-05, 5.8902344885e-05, 4.9260059297e-05, 3.0703495559e-05, 1.2600734569e-05, 1.2796435697e-06, -9.9289147392e-07, 4.3497378821e-06, 1.3511349514e-05, 2.2057285357e-05, 2.6451323853e-05, 2.5003695245e-05, 1.8079025318e-05, 7.6550917123e-06, -3.5097068354e-06, -1.2782678242e-05, -1.8362675826e-05, -1.9624018286e-05, -1.7073033543e-05, -1.2007021855e-05, -6.0310219044e-06, -5.9508829463e-07, 3.3260010889e-06, 5.3555081537e-06, 5.6526738863e-06, 4.7273710273e-06, 3.2128528431e-06, 1.6696422638e-06, 4.6611149321e-07, -2.5263380040e-07, -5.2462312568e-07, -4.9277029618e-07, -3.2339733379e-07, -1.4704207189e-07, -3.2389062140e-08, 9.7221813080e-09, 4.0943728857e-09, -1.5065458369e-08}
  COEFFICIENT_WIDTH 24
  QUANTIZATION Maximize_Dynamic_Range
  BESTPRECISION true
  FILTER_TYPE Decimation
  RATE_CHANGE_TYPE Fixed_Fractional
  INTERPOLATION_RATE 4
  DECIMATION_RATE 5
  NUMBER_CHANNELS 8
  NUMBER_PATHS 1
  SAMPLE_FREQUENCY 0.96
  CLOCK_FREQUENCY 125
  OUTPUT_ROUNDING_MODE Convergent_Rounding_to_Even
  OUTPUT_WIDTH 25
  M_DATA_HAS_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA subset_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 subset_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 3
  TDATA_REMAP {tdata[23:0]}
} {
  S_AXIS fir_1/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_2 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 24
  COEFFICIENTVECTOR {-1.5351074822e-08, -3.6843935992e-08, 3.5275653321e-09, 2.4227794291e-08, 8.1568634339e-09, 2.5161901307e-08, 4.5872765209e-09, -1.1782372436e-07, -7.8745192724e-08, 2.4309083742e-07, 2.5863739698e-07, -3.6480212874e-07, -5.8519469175e-07, 4.1637536641e-07, 1.0802775975e-06, -3.0275676666e-07, -1.7289223783e-06, -8.8899904447e-08, 2.4629579270e-06, 8.6853900881e-07, -3.1513254799e-06, -2.1140880847e-06, 3.6022040663e-06, 3.8380138562e-06, -3.5810569756e-06, -5.9563602168e-06, 2.8460606954e-06, 8.2687766197e-06, -1.1986731071e-06, -1.0458392136e-05, -1.4574634609e-06, 1.2118500166e-05, 5.0602705890e-06, -1.2809100602e-05, -9.3498848024e-06, 1.2139724057e-05, 1.3859665413e-05, -9.8709352096e-06, -1.7954228513e-05, 6.0109652030e-06, 2.0913062942e-05, -8.9301807170e-07, -2.2064163088e-05, -4.7971719766e-06, 2.0949063416e-05, 1.0062364339e-05, -1.7494695328e-05, -1.3716868475e-05, 1.2156616988e-05, 1.4590426390e-05, -5.9945060195e-06, -1.1794906623e-05, 6.4304911305e-07, 5.0169571067e-06, 1.8470296085e-06, 5.2155069002e-06, 6.9574206768e-07, -1.7355092946e-05, -1.0152519649e-05, 2.8803029375e-05, 2.7627479725e-05, -3.6087963865e-05, -5.2987300983e-05, 3.5239223596e-05, 8.4472446449e-05, -2.2390877952e-05, -1.1852532328e-04, -5.4783357176e-06, 1.4989478296e-04, 4.9753320427e-05, -1.7207880775e-04, -1.0947617367e-04, 1.7810860555e-04, 1.8087487785e-04, -1.6161771849e-04, -2.5727206595e-04, 1.1807229897e-04, 3.2948262580e-04, -4.5981641695e-05, -3.8674803046e-04, -5.2132589181e-05, 4.1816851985e-04, 1.6923413118e-04, -4.1451116695e-04, -2.9397099248e-04, 3.7009208004e-04, 4.1158253448e-04, -2.8459879206e-04, -5.0574464367e-04, 1.6428172020e-04, 5.6102609699e-04, -2.2349053804e-05, -5.6581203705e-04, -1.2177072110e-04, 5.1526722300e-04, 2.4442485789e-04, -4.1385554041e-04, -3.2095668974e-04, 2.7689140307e-04, 3.2990732802e-04, -1.3064312302e-04, -2.5775152490e-04, 1.0629267890e-05, 1.0353926398e-04, 4.2045983260e-05, 1.1729870834e-04, 1.3777341503e-05, -3.7080330774e-04, -2.1246302912e-04, 6.0439565173e-04, 5.7360104427e-04, -7.5004166200e-04, -1.0946948433e-03, 7.2994908695e-04, 1.7447193006e-03, -4.6533028278e-04, -2.4601202215e-03, -1.1261470167e-04, 3.1440763440e-03, 1.0503767677e-03, -3.6697206417e-03, -2.3597050258e-03, 3.8876020531e-03, 4.0064411985e-03, -3.6371851396e-03, -5.9019812818e-03, 2.7616608603e-03, 7.8984848207e-03, -1.1248593456e-03, -9.7884865842e-03, -1.3713712738e-03, 1.1308579538e-02, 4.7703076471e-03, -1.2147765928e-02, -9.0484904829e-03, 1.1954132149e-02, 1.4105330194e-02, -1.0340612764e-02, -1.9759571924e-02, 6.8777919712e-03, 2.5748809258e-02, -1.0594604412e-03, -3.1728288128e-02, -7.7947291889e-03, 3.7255105090e-02, 2.0791591534e-02, -4.1711998863e-02, -4.0158962700e-02, 4.3981965232e-02, 7.1509446552e-02, -4.0784585698e-02, -1.3386118600e-01, 1.2642700710e-02, 3.3827412738e-01, 5.1192977703e-01, 3.3827412738e-01, 1.2642700710e-02, -1.3386118600e-01, -4.0784585698e-02, 7.1509446552e-02, 4.3981965232e-02, -4.0158962700e-02, -4.1711998863e-02, 2.0791591534e-02, 3.7255105090e-02, -7.7947291889e-03, -3.1728288128e-02, -1.0594604412e-03, 2.5748809258e-02, 6.8777919712e-03, -1.9759571924e-02, -1.0340612764e-02, 1.4105330194e-02, 1.1954132149e-02, -9.0484904829e-03, -1.2147765928e-02, 4.7703076471e-03, 1.1308579538e-02, -1.3713712738e-03, -9.7884865842e-03, -1.1248593456e-03, 7.8984848207e-03, 2.7616608603e-03, -5.9019812818e-03, -3.6371851396e-03, 4.0064411985e-03, 3.8876020531e-03, -2.3597050258e-03, -3.6697206417e-03, 1.0503767677e-03, 3.1440763440e-03, -1.1261470167e-04, -2.4601202215e-03, -4.6533028278e-04, 1.7447193006e-03, 7.2994908695e-04, -1.0946948433e-03, -7.5004166200e-04, 5.7360104427e-04, 6.0439565173e-04, -2.1246302912e-04, -3.7080330774e-04, 1.3777341503e-05, 1.1729870834e-04, 4.2045983260e-05, 1.0353926398e-04, 1.0629267890e-05, -2.5775152490e-04, -1.3064312302e-04, 3.2990732802e-04, 2.7689140307e-04, -3.2095668974e-04, -4.1385554041e-04, 2.4442485789e-04, 5.1526722300e-04, -1.2177072110e-04, -5.6581203705e-04, -2.2349053804e-05, 5.6102609699e-04, 1.6428172020e-04, -5.0574464367e-04, -2.8459879206e-04, 4.1158253448e-04, 3.7009208004e-04, -2.9397099248e-04, -4.1451116695e-04, 1.6923413118e-04, 4.1816851985e-04, -5.2132589181e-05, -3.8674803046e-04, -4.5981641695e-05, 3.2948262580e-04, 1.1807229897e-04, -2.5727206595e-04, -1.6161771849e-04, 1.8087487785e-04, 1.7810860555e-04, -1.0947617367e-04, -1.7207880775e-04, 4.9753320427e-05, 1.4989478296e-04, -5.4783357176e-06, -1.1852532328e-04, -2.2390877952e-05, 8.4472446449e-05, 3.5239223596e-05, -5.2987300983e-05, -3.6087963865e-05, 2.7627479725e-05, 2.8803029375e-05, -1.0152519649e-05, -1.7355092946e-05, 6.9574206768e-07, 5.2155069002e-06, 1.8470296085e-06, 5.0169571067e-06, 6.4304911305e-07, -1.1794906623e-05, -5.9945060195e-06, 1.4590426390e-05, 1.2156616988e-05, -1.3716868475e-05, -1.7494695328e-05, 1.0062364339e-05, 2.0949063416e-05, -4.7971719766e-06, -2.2064163088e-05, -8.9301807171e-07, 2.0913062942e-05, 6.0109652030e-06, -1.7954228513e-05, -9.8709352096e-06, 1.3859665413e-05, 1.2139724057e-05, -9.3498848024e-06, -1.2809100602e-05, 5.0602705890e-06, 1.2118500166e-05, -1.4574634609e-06, -1.0458392136e-05, -1.1986731071e-06, 8.2687766197e-06, 2.8460606954e-06, -5.9563602168e-06, -3.5810569756e-06, 3.8380138562e-06, 3.6022040663e-06, -2.1140880847e-06, -3.1513254799e-06, 8.6853900881e-07, 2.4629579270e-06, -8.8899904447e-08, -1.7289223783e-06, -3.0275676666e-07, 1.0802775975e-06, 4.1637536641e-07, -5.8519469175e-07, -3.6480212874e-07, 2.5863739698e-07, 2.4309083742e-07, -7.8745192724e-08, -1.1782372436e-07, 4.5872765209e-09, 2.5161901307e-08, 8.1568634339e-09, 2.4227794291e-08, 3.5275653321e-09, -3.6843935992e-08, -1.5351074822e-08}
  COEFFICIENT_WIDTH 24
  QUANTIZATION Maximize_Dynamic_Range
  BESTPRECISION true
  FILTER_TYPE Decimation
  DECIMATION_RATE 2
  NUMBER_CHANNELS 8
  NUMBER_PATHS 1
  SAMPLE_FREQUENCY 0.768
  CLOCK_FREQUENCY 125
  OUTPUT_ROUNDING_MODE Convergent_Rounding_to_Even
  OUTPUT_WIDTH 26
  M_DATA_HAS_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA subset_1/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 32
} {
  S_AXIS fir_2/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 subset_2 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 32
  M_TDATA_NUM_BYTES 32
  TDATA_REMAP {tdata[23:16],tdata[39:32],tdata[47:40],tdata[55:48],16'b0000000000000000,tdata[7:0],tdata[15:8],tdata[87:80],tdata[103:96],tdata[111:104],tdata[119:112],16'b0000000000000000,tdata[71:64],tdata[79:72],tdata[151:144],tdata[167:160],tdata[175:168],tdata[183:176],16'b0000000000000000,tdata[135:128],tdata[143:136],tdata[215:208],tdata[231:224],tdata[239:232],tdata[247:240],16'b0000000000000000,tdata[199:192],tdata[207:200]}
} {
  S_AXIS conv_1/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create fifo_generator
cell xilinx.com:ip:fifo_generator:13.0 fifo_generator_0 {
  PERFORMANCE_OPTIONS First_Word_Fall_Through
  INPUT_DATA_WIDTH 256
  INPUT_DEPTH 1024
  OUTPUT_DATA_WIDTH 32
  OUTPUT_DEPTH 8192
  READ_DATA_COUNT true
  READ_DATA_COUNT_WIDTH 14
} {
  clk /ps_0/FCLK_CLK0
  srst slice_0/Dout
}

# Create axis_fifo
cell pavel-demin:user:axis_fifo:1.0 fifo_1 {
  S_AXIS_TDATA_WIDTH 256
  M_AXIS_TDATA_WIDTH 32
} {
  S_AXIS subset_2/M_AXIS
  FIFO_READ fifo_generator_0/FIFO_READ
  FIFO_WRITE fifo_generator_0/FIFO_WRITE
  aclk /ps_0/FCLK_CLK0
}

# Create axi_axis_reader
cell pavel-demin:user:axi_axis_reader:1.0 reader_0 {
  AXI_DATA_WIDTH 32
} {
  S_AXIS fifo_1/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}
