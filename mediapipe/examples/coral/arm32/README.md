# Raspberry Pi Setup (experimental)

**Dislaimer**: Running MediaPipe on Coral is experimental, and this process may
not be exact and is subject to change. These instructions have only been tested
on the [Coral Dev Board](https://coral.ai/products/dev-board/) with Mendel 4.0,
and may vary for different devices and workstations.

This file describes how to prepare a Coral Dev Board and setup a Linux
Docker container for building MediaPipe applications that run on Edge TPU.

## Before creating the Docker

* (on host machine) run _setup.sh_ from MediaPipe root directory

        sh mediapipe/examples/coral/arm32/setup.sh

* (on host machine) Download the Raspberry Pi OpenCV libs

        # from mediapipe root level directory #
        curl -L https://github.com/lisaong/stackup-workshops/raw/master/pi-mediapipe/cross_compile/libs/3.4.7/arm-linux-gnueabihf.tgz -o opencv.tgz
        tar zcvf opencv.tgz
        mv arm-linux-gnueabihf/* opencv34_arm32_libs/.
        rm -rf arm-linux-gnueabihf opencv.tgz

* (on host machine) Start the docker environment

        # from mediapipe root level directory #
        docker run -it --name coral lisaong/coral-arm32-opencv:3.4.7

## Inside the Docker environment

* Update library paths in /mediapipe/third_party/opencv_linux.BUILD

  (replace 'x86_64-linux-gnu' with 'arm-linux-gnueabihf')

        "lib/arm-linux-gnueabihf/libopencv_core.so",
        "lib/arm-linux-gnueabihf/libopencv_calib3d.so",
        "lib/arm-linux-gnueabihf/libopencv_features2d.so",
        "lib/arm-linux-gnueabihf/libopencv_highgui.so",
        "lib/arm-linux-gnueabihf/libopencv_imgcodecs.so",
        "lib/arm-linux-gnueabihf/libopencv_imgproc.so",
        "lib/arm-linux-gnueabihf/libopencv_video.so",
        "lib/arm-linux-gnueabihf/libopencv_videoio.so",

* Attempt to build hello world (to download external deps)

        bazel build -c opt --define MEDIAPIPE_DISABLE_GPU=1 mediapipe/examples/desktop/hello_world:hello_world

* Edit  /mediapipe/bazel-mediapipe/external/com_github_glog_glog/src/signalhandler.cc

      on line 78, replace

        return (void*)context->PC_FROM_UCONTEXT;

      with

        return NULL;

* Edit /edgetpu/libedgetpu/BUILD

      to add this build target

         cc_library(
           name = "lib",
           srcs = [
               "libedgetpu.so",
           ],
           visibility = ["//visibility:public"],
         )

* Edit /mediapipe/mediapipe/calculators/tflite/BUILD to change rules for *tflite_inference_calculator.cc*

        sed -i 's/\":tflite_inference_calculator_cc_proto\",/\":tflite_inference_calculator_cc_proto\",\n\t\"@edgetpu\/\/:header\",\n\t\"@libedgetpu\/\/:lib\",/g' /mediapipe/mediapipe/calculators/tflite/BUILD

      The above command should add

        "@edgetpu//:header",
        "@libedgetpu//:lib",

      to the _deps_ of tflite_inference_calculator.cc

#### Now try cross-compiling for device

* Object detection demo

        bazel build -c opt --crosstool_top=@crosstool//:toolchains --compiler=gcc --cpu=armhf --define MEDIAPIPE_DISABLE_GPU=1 --copt -DMEDIAPIPE_EDGE_TPU --copt=-flax-vector-conversions mediapipe/examples/coral:object_detection_tpu

 Copy object_detection_tpu binary to the MediaPipe checkout on the device

        # outside docker env, open new terminal on host machine #
        docker ps
        docker cp <container-id>:/mediapipe/bazel-bin/mediapipe/examples/coral/object_detection_tpu /tmp/.
        mdt push /tmp/object_detection_tpu /home/mendel/mediapipe/bazel-bin/.

* Face detection demo

        bazel build -c opt --crosstool_top=@crosstool//:toolchains --compiler=gcc --cpu=armhf --define MEDIAPIPE_DISABLE_GPU=1 --copt -DMEDIAPIPE_EDGE_TPU --copt=-flax-vector-conversions mediapipe/examples/coral:face_detection_tpu

 Copy face_detection_tpu binary to the MediaPipe checkout on the device

        # outside docker env, open new terminal on host machine #
        docker ps
        docker cp <container-id>:/mediapipe/bazel-bin/mediapipe/examples/coral/face_detection_tpu /tmp/.
        mdt push /tmp/face_detection_tpu /home/mendel/mediapipe/bazel-bin/.

## On the device (with display)

     # Object detection
     cd ~/mediapipe
     chmod +x bazel-bin/object_detection_tpu
     export GLOG_logtostderr=1
     bazel-bin/object_detection_tpu --calculator_graph_config_file=mediapipe/examples/coral/graphs/object_detection_desktop_live.pbtxt

     # Face detection
     cd ~/mediapipe
     chmod +x bazel-bin/face_detection_tpu
     export GLOG_logtostderr=1
     bazel-bin/face_detection_tpu --calculator_graph_config_file=mediapipe/examples/coral/graphs/face_detection_desktop_live.pbtxt

