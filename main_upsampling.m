% 《信号与线性系统》工程设计题 6：上采样
% 操作：在 MATLAB 中打开本文件，点击“运行”，或按 F5。
% 本脚本从自身所在文件夹读取 zebra.jpg，结果写入 results 子文件夹。
% 原始 PDF 和 JPG 不会被覆盖。只需要基础 MATLAB。

clear;
clc;
projectDir = fileparts(mfilename('fullpath'));
addpath(projectDir);                          % 让 MATLAB 找到同文件夹中的函数
resultDir = fullfile(projectDir, 'results');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end
diary off;
validationLog = fullfile(resultDir, 'validation.txt');
if exist(validationLog, 'file')
    delete(validationLog);                   % 只更新本项目生成的旧验证日志
end
diary(validationLog);
diaryCleanup = onCleanup(@() diary('off'));   % 即使后面发生错误也结束日志记录
fprintf('MATLAB %s\n', version);

%% 1. 一维：插零后用三角形核卷积
L = 3;
x = [3 5 2 2.5];                            % 题图未给出幅值，这是演示数据
[y, n, w, nw, f, nf] = linear_upsample_1d(x, L);
nx = 0:length(x)-1;
fprintf('\n1D demonstration x = [3 5 2 2.5], L = 3\n');
fprintf('Kernel indices: '); fprintf('%g ', nf); fprintf('\n');
fprintf('Kernel values:  '); fprintf('%.8g ', f); fprintf('\n');
disp(table(n(:), y(:), 'VariableNames', {'n', 'y'}));
writetable(table(n(:), y(:), 'VariableNames', {'n', 'y'}), ...
    fullfile(resultDir, 'one_dimensional_values.csv'));

fig1 = figure('Color', 'w', 'Position', [100 100 1100 850]);
subplot(3, 1, 1);
stem(-1:4, [0 x 0], 'filled', 'LineWidth', 1.2);
grid on; xlim([-1.5 4.5]); ylim([0 5.7]);
xlabel('n'); ylabel('x[n]');
title('Original samples (illustrative amplitudes)');
subplot(3, 1, 2);
stem(-L:L*(length(x)), [zeros(1,L) w zeros(1,L)], 'filled', 'LineWidth', 1.1);
grid on; xlim([-3.5 12.5]); ylim([0 5.7]);
xlabel('n'); ylabel('w[n]'); title('Insert two zeros between adjacent samples');
subplot(3, 1, 3);
stem([n(1)-1 n n(end)+1], [0 y 0], 'filled', 'LineWidth', 1.1);
hold on;
plot([-L L*nx L*length(x)], [0 x 0], '--', 'Color', [0.45 0.45 0.45]);
plot(L*nx, x, 'ro', 'MarkerSize', 8, 'LineWidth', 1.2);
grid on; xlim([-3.5 12.5]); ylim([0 5.7]);
xlabel('n'); ylabel('y[n]'); title('Linear interpolation: y[n] = w[n] * f[n]');
legend('Output samples', 'Linear segments', 'Preserved original samples', 'Location', 'best');
save_light_figure(fig1, resultDir, '01_1d_upsampling', 160);

%% 2. 一维核、二维可分离核与频率响应
F = f(:)*f(:).';                            % F[p,q] = f[p]f[q]
omega = linspace(-pi, pi, 1501);
Fw = f * exp(-1j*nf(:)*omega);               % 按定义计算 DTFT，不需要 freqz
fig2 = figure('Color', 'w', 'Position', [120 120 1200 380]);
subplot(1, 3, 1);
stem(-L:L, [0 f 0], 'filled', 'LineWidth', 1.2);
grid on; xlabel('n'); ylabel('f[n]'); title('1D triangular kernel, L = 3');
subplot(1, 3, 2);
surf(nf, nf, F); xlabel('q'); ylabel('p'); zlabel('F[p,q]');
title('2D separable kernel'); axis tight; view(35, 30);
subplot(1, 3, 3);
plot(omega/pi, real(Fw)/L, 'LineWidth', 1.4);
grid on; xlim([-1 1]); ylim([0 1.05]);
xlabel('\omega / \pi'); ylabel('F(e^{j\omega}) / L');
title('Normalized frequency response');
save_light_figure(fig2, resultDir, '02_interpolation_kernel', 160);

%% 3. 将原始 zebra.jpg 的行数和列数分别扩大 3 倍
sourceFile = fullfile(projectDir, 'zebra.jpg');
assert(exist(sourceFile, 'file') == 2, '请把原始 zebra.jpg 放在本脚本所在文件夹。');
I = double(imread(sourceFile));               % 原始 JPG 解码后的像素值
assert(ismatrix(I), '本作业提供的是灰度图；当前示例绘图要求二维灰度输入。');
[H, W] = size(I);
tic;
Y = bilinear_upsample_conv(I, L);             % 手动插零 + 两次 conv2
elapsed = toc;
nearest = kron(I, ones(L));                  % 最近邻对照，仅用于结果比较
Y8 = uint8(round(min(max(Y, 0), 255)));       % 保存 PNG 前才量化为 8 位
imwrite(Y8, fullfile(resultDir, 'zebra_3x_bilinear.png'));
imwrite(uint8(nearest), fullfile(resultDir, 'zebra_3x_nearest.png'));

fig3 = figure('Color', 'w', 'Position', [140 140 1200 500]);
subplot(1, 3, 1); imagesc(I, [0 255]); axis image off;
title(sprintf('Source: %d x %d (H x W)', H, W));
subplot(1, 3, 2); imagesc(nearest, [0 255]); axis image off;
title(sprintf('Nearest neighbor: %d x %d', L*H, L*W));
subplot(1, 3, 3); imagesc(Y8, [0 255]); axis image off;
title(sprintf('Bilinear via convolution: %d x %d', L*H, L*W));
colormap(fig3, gray(256));
save_light_figure(fig3, resultDir, '03_zebra_comparison', 160);

% 选择条纹区域；按原图坐标截取，比较相同空间范围。
roiRows = 85:125;
roiCols = 75:115;
outR = L*(roiRows(1)-1)+(1:L*numel(roiRows));
outC = L*(roiCols(1)-1)+(1:L*numel(roiCols));
fig4 = figure('Color', 'w', 'Position', [160 160 1000 480]);
subplot(1, 2, 1); imagesc(nearest(outR, outC), [0 255]); axis image off;
title('Nearest neighbor: stripe detail');
subplot(1, 2, 2); imagesc(Y8(outR, outC), [0 255]); axis image off;
title('Bilinear: stripe detail');
colormap(fig4, gray(256));
save_light_figure(fig4, resultDir, '04_stripe_detail', 200);

%% 4. 验证：独立插值、原像素、边界、仿射平面等
fprintf('\nIndependent algorithm checks\n');
checks = test_upsampling();
[qc, qr] = meshgrid(min(1+(0:L*W-1)/L, W), min(1+(0:L*H-1)/L, H));
reference = interp2(I, qc, qr, 'linear');      % 只用于验证，不用于生成结果图
referenceError = max(abs(Y(:)-reference(:)));
referenceRMSE = sqrt(mean((Y(:)-reference(:)).^2));
anchors = Y(1:L:end, 1:L:end);
anchorError = max(abs(anchors(:)-I(:)));
quantizationError = max(abs(double(Y8(:))-Y(:)));
assert(isequal(size(Y), [L*H L*W]), '输出尺寸不等于原图的 3 倍。');
assert(referenceError < 1e-10, '与独立 interp2 参考的误差超过容限。');
assert(anchorError < 1e-10, '原始像素未被保留。');
assert(quantizationError <= 0.5+1e-10, 'PNG 量化误差异常。');

% 用白色常量图展示：不做边界扩展会导致右下边界变暗。
white = 255*ones(6, 8);
Z0 = zeros(L*6, L*8);
Z0(1:L:end, 1:L:end) = white;
naive = conv2(conv2(Z0, f(:), 'same'), f(:).', 'same');
correct = bilinear_upsample_conv(white, L);
naiveBorderError = max(abs(naive(:)-255));
correctBorderError = max(abs(correct(:)-255));
fig5 = figure('Color', 'w', 'Position', [180 180 1100 370]);
subplot(1, 3, 1); imagesc(naive, [0 255]); axis image;
title('Zero extension: dark right/bottom borders');
xlabel('Column'); ylabel('Row');
subplot(1, 3, 2); imagesc(correct, [0 255]); axis image;
title('Replicated boundaries: constant preserved');
xlabel('Column'); ylabel('Row');
subplot(1, 3, 3);
plot(naive(end, :), 'o-', 'LineWidth', 1.2); hold on;
plot(correct(end, :), 's-', 'LineWidth', 1.2);
grid on; xlabel('Column'); ylabel('Gray value'); ylim([0 270]);
title('Last-row pixel values'); legend('Zero extension', 'Replicate', 'Location', 'best');
colormap(fig5, gray(256));
save_light_figure(fig5, resultDir, '05_boundary_validation', 160);

% 倍数改变只增加网格密度，不增加真实图像细节。
scales = [2 3 4];
rowsOut = zeros(3, 1); colsOut = rowsOut; gains = rowsOut; sampleErr = rowsOut;
fig6 = figure('Color', 'w', 'Position', [200 200 1100 450]);
for k = 1:numel(scales)
    s = scales(k);
    [Ys, fs] = bilinear_upsample_conv(I, s);
    rowsOut(k) = size(Ys, 1); colsOut(k) = size(Ys, 2); gains(k) = sum(fs);
    samples = Ys(1:s:end, 1:s:end);
    sampleErr(k) = max(abs(samples(:)-I(:)));
    subplot(1, 3, k);
    rr = s*(roiRows(1)-1)+(1:s*numel(roiRows));
    cc = s*(roiCols(1)-1)+(1:s*numel(roiCols));
    imagesc(Ys(rr, cc), [0 255]); axis image off;
    title(sprintf('L = %d: %d x %d', s, s*H, s*W));
end
colormap(fig6, gray(256));
save_light_figure(fig6, resultDir, '06_scale_comparison', 160);
scaleTable = table(scales(:), rowsOut, colsOut, gains, sampleErr, ...
    'VariableNames', {'L', 'height', 'width', 'kernel_sum', 'anchor_max_error'});
writetable(scaleTable, fullfile(resultDir, 'scale_metrics.csv'));

%% 5. 保存可复核的数值、指标和验证记录
metrics = struct;
metrics.matlab_version = version;
metrics.input_height = H;
metrics.input_width = W;
metrics.scale = L;
metrics.output_height = size(Y, 1);
metrics.output_width = size(Y, 2);
metrics.kernel_indices = nf;
metrics.kernel_coefficients = f;
metrics.kernel_sum = sum(f);
metrics.reference_max_abs_error = referenceError;
metrics.reference_rmse = referenceRMSE;
metrics.original_sample_max_abs_error = anchorError;
metrics.uint8_quantization_max_abs_error = quantizationError;
metrics.zero_extension_constant_max_abs_error = naiveBorderError;
metrics.replicated_boundary_constant_max_abs_error = correctBorderError;
metrics.input_min = min(I(:));
metrics.input_max = max(I(:));
metrics.output_min = min(Y(:));
metrics.output_max = max(Y(:));
metrics.convolution_elapsed_seconds = elapsed;
metrics.test_count = numel(checks);
metrics.tests_passed = nnz([checks.passed]);
metrics.coordinate_convention = 'origin-aligned: (output_index-1)/L, clamped to last source pixel';
fid = fopen(fullfile(resultDir, 'metrics.json'), 'w', 'n', 'UTF-8');
assert(fid >= 0, '无法创建 metrics.json。');
fprintf(fid, '%s\n', jsonencode(metrics, 'PrettyPrint', true));
fclose(fid);
writetable(struct2table(checks), fullfile(resultDir, 'test_results.csv'));
save(fullfile(resultDir, 'experiment_data.mat'), ...
    'I', 'Y', 'Y8', 'nearest', 'x', 'y', 'n', 'w', 'nw', 'f', 'nf', 'F', ...
    'metrics', 'checks', 'scaleTable');
fprintf('\nSource: %d x %d; result: %d x %d (H x W).\n', H, W, size(Y, 1), size(Y, 2));
fprintf('Original-sample max error: %.6g\n', anchorError);
fprintf('Independent interp2 max error: %.6g; RMSE: %.6g\n', referenceError, referenceRMSE);
fprintf('PNG quantization max error: %.6g gray levels\n', quantizationError);
fprintf('Convolution elapsed: %.6g seconds (single run, not a benchmark).\n', elapsed);
fprintf('ALL CHECKS PASSED. Results folder: %s\n', resultDir);
diary off;
clear diaryCleanup;

function save_light_figure(fig, resultDir, name, resolution)
% 统一为白底黑字，避免 MATLAB 深色主题使导出的报告图难以阅读。
if isprop(fig, 'Theme')
    fig.Theme = 'light';
end
fig.Color = 'w';
set(findall(fig, 'Type', 'axes'), 'Color', 'w', ...
    'XColor', 'k', 'YColor', 'k', 'ZColor', 'k', 'FontSize', 11);
set(findall(fig, 'Type', 'text'), 'Color', 'k');
set(findall(fig, 'Type', 'legend'), 'Color', 'w', ...
    'TextColor', 'k', 'EdgeColor', [0.3 0.3 0.3]);
exportgraphics(fig, fullfile(resultDir, [name '.png']), ...
    'Resolution', resolution, 'BackgroundColor', 'white');
savefig(fig, fullfile(resultDir, [name '.fig']));
end
