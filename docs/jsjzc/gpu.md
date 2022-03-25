### 图形渲染
- 现在电脑里面显示出来的 3D 的画面，其实是通过多边形组合出来的
- 你在玩的各种游戏，里面的人物的脸，并不是那个相机或者摄像头拍出来的，而是通过多边形建模（Polygon Modeling）创建出来的
![](/images/jsjzc/tuxingxuanran.jpeg)

### 图形实时渲染步骤（图形流水线）
1. 顶点处理 Vertex Processing
2. 图元处理 Primitive Processing
3. 栅格化 Rasterization
4. 片段处理 Fragment Processing
5. 像素操作 Pixel Operations

#### 顶点处理
- 构成多边形建模的每个多边形都有多个顶点
- 每个顶点在三维空间里有一个坐标
- 因为屏幕是二维的，所以需要把顶点的三维空间里边的位置，转化到屏幕这个二维空间里边的操作叫顶点处理
- 通过线性代数计算
- `每个顶点位置的转换，互相之间没有依赖关系，可以并行独立计算`
![1111](/images/jsjzc/dingdianchuli.jpeg)

#### 图元处理
- 把顶点处理完成之后的各个顶点连起来，变成多边形
- 转化后的顶点，仍然是在一个三维空间里，只是第三维的 Z 轴，是正对屏幕的“深度”
- 针对这些多边形，需要做一个操作，叫剔除和裁剪（Cull and Clip），也就是把不在屏幕里面，或者一部分不在屏幕里面的内容给去掉，减少接下来流程的工作量
![](/images/jsjzc/tuyuanchuli.jpeg)

#### 栅格化
- 把多边形转换成屏幕里面的一个个像素点
- 每一个图元都可以并行处理
![](/images/jsjzc/shangehua.jpeg)

#### 片段处理
- 栅格化后的图像是黑白的
- 需要计算每个像素的颜色和透明度，给像素上色
- 同样可以并行，独立进行
![](/images/jsjzc/pianduanchuli.jpeg)

#### 像素操作
- 把不同的像素点混合到一起，最终输出到显示设备

![](/images/jsjzc/tupianpipline.jpeg)
