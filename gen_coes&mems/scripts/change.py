import os
import uuid
from ffmpy import FFmpeg
 
 
# 调整图片大小
def change_size(image_path: str, output_dir: str, width: int, height: int):
    ext = os.path.basename(image_path).strip().split('.')[-1]
    if ext not in ['png', 'jpg']:
        raise Exception('format error')
    _result_path = os.path.join(
        output_dir, '{}.{}'.format(
            uuid.uuid1().hex, ext))
    ff = FFmpeg(inputs={'{}'.format(image_path): None}, outputs={
        _result_path: '-vf scale={}:{}'.format(width, height)})
    print(ff.cmd)
    ff.run()
    return _result_path

if __name__ == '__main__':
    print(change_size('F:\\Vivado\\pro.jpg', 'F:\\Vivado\\', 160, 120))