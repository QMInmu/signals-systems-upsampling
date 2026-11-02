function [y, n, w, nw, f, nf] = linear_upsample_1d(x, L)
%LINEAR_UPSAMPLE_1D 用“插零 + 卷积”实现一维 L 倍线性插值。
% x 的数学下标从 0 开始，有限序列以外按 0 处理。
% y 使用完整卷积；n 是 y 对应的数学下标，不能把数组位置当成 n。

validateattributes(x, {'numeric'}, {'vector', 'nonempty', 'finite'}, mfilename, 'x');
validateattributes(L, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'L');
x = double(x(:).');                 % 转成行向量，.' 不进行复共轭
N = length(x) - 1;                  % x 的最后一个数学下标

nw = 0:L*N;                        % 插零序列的数学下标
w = zeros(1, L*N + 1);              % 先创建全零数组
w(1:L:end) = x;                    % 把原样本放在 n = 0,L,2L,...

nf = -(L-1):(L-1);                 % 三角形核的数学下标
f = 1 - abs(nf)/L;                 % f[n] = max(1-|n|/L,0)
y = conv(w, f);                    % 完整离散卷积，包含两端过渡
n = (nw(1)+nf(1)):(nw(end)+nf(end));
end
