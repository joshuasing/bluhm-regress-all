export REGRESS_FAIL_EARLY=no
export TEST_SSH_UNSAFE_PERMISSIONS=yes

LOCAL_IF=em1
LOCAL_MAC=90:e2:ba:d8:67:2d
LOCAL_ADDR=10.188.81.22
LOCAL_NET=10.188.81.22/24
FAKE_ADDR=10.188.81.188

LOCAL_ADDR6=fdd7:e83e:66bc:81::22
LOCAL_NET6=fdd7:e83e:66bc:81::22
FAKE_ADDR6=fdd7:e83e:66bc:81::188

export LOCAL_IF LOCAL_MAC
export LOCAL_ADDR LOCAL_NET FAKE_ADDR
export LOCAL_ADDR6 LOCAL_NET6 FAKE_ADDR6
