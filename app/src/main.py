import os
import traceback

mpv_dylib_path = os.environ['ANDROID_NATIVE_LIBRARY_DIR'] + '/libmpv.so'
os.environ['MPV_DYLIB_PATH'] = mpv_dylib_path

from feeluown.entry_points.run import run

try:

    run()
except Exception as e:
    with open('feeluown_err.stack', 'w') as f:
        traceback.print_exception(e, file=f)
    raise
