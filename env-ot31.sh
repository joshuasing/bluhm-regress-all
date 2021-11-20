LOCAL_IF=ixl0
LOCAL_ADDR=10.6.12.51
LOCAL_ADDR6=fdd7:e83e:66bc:0612::51

REMOTE_IF=ixl1
REMOTE_ADDR=10.6.12.52
REMOTE_ADDR6=fdd7:e83e:66bc:0612::52
REMOTE_SSH=ot32

LINUX_ADDR=10.6.16.36
LINUX_ADDR6=fdd7:e83e:66bc:0616::36
LINUX_FORWARD_ADDR=10.6.16.36
LINUX_FORWARD_ADDR6=fdd7:e83e:66bc:0616::36
LINUX_RELAY_ADDR=10.6.31.51
LINUX_RELAY_ADDR6=fdd7:e83e:66bc:0631::51
LINUX_SSH=perform@lt13

LINUX_RELAY_LOCAL_ADDR=10.6.26.52
LINUX_RELAY_LOCAL_ADDR6=fdd7:e83e:66bc:0626::52
LINUX_RELAY_REMOTE_ADDR=10.6.16.51
LINUX_RELAY_REMOTE_ADDR6=fdd7:e83e:66bc:0616::51
LINUX_OTHER_SSH=perform@lt16

LOCAL_IPSEC_ADDR=10.7.31.51
LOCAL_IPSEC_ADDR6=fdd7:e83e:66bc:0731::51
REMOTE_IPSEC_ADDR=10.7.26.52
REMOTE_IPSEC_ADDR6=fdd7:e83e:66bc:0726::52
LINUX_IPSEC_ADDR=10.7.26.36
LINUX_IPSEC_ADDR6=fdd7:e83e:66bc:0726::36
LOCAL_IPSEC6_ADDR=10.8.31.51
LOCAL_IPSEC6_ADDR6=fdd7:e83e:66bc:0831::51
REMOTE_IPSEC6_ADDR=10.8.26.52
REMOTE_IPSEC6_ADDR6=fdd7:e83e:66bc:0826::52
LINUX_IPSEC6_ADDR=10.8.26.36
LINUX_IPSEC6_ADDR6=fdd7:e83e:66bc:0826::36
LOCAL_IPSEC_TRANS_ADDR=10.9.12.51
LOCAL_IPSEC_TRANS_ADDR6=fdd7:e83e:66bc:0912::51
REMOTE_IPSEC_TRANS_ADDR=10.9.12.52
REMOTE_IPSEC_TRANS_ADDR6=fdd7:e83e:66bc:0912::52

export LOCAL_IF LOCAL_ADDR LOCAL_ADDR6
export REMOTE_IF REMOTE_ADDR REMOTE_ADDR6
export REMOTE_SSH
export LINUX_ADDR LINUX_ADDR6 LINUX_FORWARD_ADDR LINUX_FORWARD_ADDR6
export LINUX_RELAY_ADDR LINUX_RELAY_ADDR6
export LINUX_SSH
export LINUX_RELAY_LOCAL_ADDR LINUX_RELAY_LOCAL_ADDR6
export LINUX_RELAY_REMOTE_ADDR LINUX_RELAY_REMOTE_ADDR6
export LINUX_OTHER_SSH
export LOCAL_IPSEC_ADDR REMOTE_IPSEC_ADDR LINUX_IPSEC_ADDR
export LOCAL_IPSEC_ADDR6 REMOTE_IPSEC_ADDR6 LINUX_IPSEC_ADDR6
export LOCAL_IPSEC6_ADDR REMOTE_IPSEC6_ADDR LINUX_IPSEC6_ADDR
export LOCAL_IPSEC6_ADDR6 REMOTE_IPSEC6_ADDR6 LINUX_IPSEC6_ADDR6
export LOCAL_IPSEC_TRANS_ADDR REMOTE_IPSEC_TRANS_ADDR
export LOCAL_IPSEC_TRANS_ADDR6 REMOTE_IPSEC_TRANS_ADDR6
