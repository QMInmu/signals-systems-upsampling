function [Y, f] = bilinear_upsample_conv(I, L)
%BILINEAR_UPSAMPLE_CONV 用二维插零和可分离卷积放大图像。
% 输入：灰度 H×W 或多通道 H×W×C 数组，整数倍数 L。
% 输出：double 类型的 (L*H)×(L*W)×C 数组，不自动量化。
% 坐标约定：Y(L*i+1,L*j+1,:) = I(i+1,j+1,:)（i,j 从 0 开始）。
% 边界约定：重复边界像素。输出最后 L-1 行/列位于复制区域。
% 核心计算只使用基础 MATLAB 的 conv2，不使用 imresize。

validateattributes(I, {'numeric', 'logical'}, ...
    {'real', 'finite', 'nonempty', 'nonsparse'}, mfilename, 'I');
assert(ndims(I) <= 3, 'I 必须是二维灰度图或三维多通道图像。');
validateattributes(L, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'L');
I = double(I);                      % 整数图像先转 double，避免计算时舍入
[H, W, C] = size(I);
nf = -(L-1):(L-1);
f = 1 - abs(nf)/L;                 % 一维三角形核，系数和为 L
Y = zeros(L*H, L*W, C);

rows = [1, 1:H, H];                % 在上下各复制一行
cols = [1, 1:W, W];                % 在左右各复制一列
outRows = L + (1:L*H);             % 去掉扩展边界后要保留的区域
outCols = L + (1:L*W);

for c = 1:C                        % 灰度图循环一次；彩色图逐通道处理
    P = I(rows, cols, c);          % 原图两侧各增加一个边界样本
    Z = zeros(L*(H+1)+1, L*(W+1)+1);
    Z(1:L:end, 1:L:end) = P;       % 行和列都插入 L-1 个零
    T = conv2(Z, f(:), 'same');    % 先在竖直方向做线性插值
    T = conv2(T, f(:).', 'same');  % 再在水平方向做线性插值
    Y(:, :, c) = T(outRows, outCols);
end
end
