function checks = test_upsampling()
%TEST_UPSAMPLING 独立的数值验证，不需要图像处理工具箱。
% 验证手算结果、interp1/interp2 对照、边界、常量、仿射平面和多通道。

tol = 1e-10;
checks = struct('name', {}, 'max_abs_error', {}, 'passed', {});

[y, n, ~, ~, f] = linear_upsample_1d([3 5 2 2.5], 3);
expected = [1 2 3 11/3 13/3 5 4 3 2 13/6 7/3 2.5 5/3 5/6];
checks(end+1) = check('1D hand-calculated sequence', y, expected, tol);
ref1 = interp1([-3 0 3 6 9 12], [0 3 5 2 2.5 0], n, 'linear');
checks(end+1) = check('1D independent interp1 reference', y, ref1, tol);
checks(end+1) = check('1D original samples and kernel gain', ...
    [y(ismember(n, [0 3 6 9])), sum(f)], [3 5 2 2.5 3], tol);
for L = [1 2 4]
    [y, n] = linear_upsample_1d([3 5 2 2.5], L);
    ref1 = interp1(L*(-1:4), [0 3 5 2 2.5 0], n, 'linear');
    checks(end+1) = check(sprintf('1D interp1 reference L=%d', L), y, ref1, tol);
end

Y = bilinear_upsample_conv([0 30; 60 90], 3);
q = min((0:5)/3, 1);
ref2 = 60*q(:) + 30*q;
checks(end+1) = check('2D hand-calculated 2-by-2 plane including borders', Y, ref2, tol);

constant = 137*ones(4, 5);
Y = bilinear_upsample_conv(constant, 3);
checks(end+1) = check('Constant image including four borders', Y, 137*ones(12, 15), tol);

I = reshape(1:20, 4, 5);
for L = [1 2 3 4]
    Y = bilinear_upsample_conv(I, L);
    [qc, qr] = meshgrid(min(1+(0:L*5-1)/L, 5), min(1+(0:L*4-1)/L, 4));
    ref = interp2(I, qc, qr, 'linear');
    checks(end+1) = check(sprintf('2D interp2 reference L=%d', L), Y, ref, tol);
end

[cc, rr] = meshgrid(0:5, 0:4);
I = 7 + 2*rr + 3*cc;
Y = bilinear_upsample_conv(I, 3);
[cq, rq] = meshgrid((0:15)/3, (0:12)/3);
ref = 7 + 2*rq + 3*cq;
checks(end+1) = check('Affine-plane exactness inside original domain', Y(1:13, 1:16), ref, tol);

checks(end+1) = check('Single-pixel image boundary handling', ...
    bilinear_upsample_conv(42, 3), 42*ones(3), tol);
row = [0 6 12];
refrow = repmat([0 2 4 6 8 10 12 12 12], 3, 1);
checks(end+1) = check('Single-row image', bilinear_upsample_conv(row, 3), refrow, tol);
checks(end+1) = check('Single-column image', bilinear_upsample_conv(row.', 3), refrow.', tol);

base = [0 30; 60 90];
rgb = cat(3, base, base+20, 255-base);
Y = bilinear_upsample_conv(rgb, 3);
q = min((0:5)/3, 1);
ref = 60*q(:) + 30*q;
checks(end+1) = check('RGB channels processed independently', ...
    Y, cat(3, ref, ref+20, 255-ref), tol);

% 用完整二维核卷积作为另一种运算路径，验证可分离性。
I = reshape(sin(1:20), 4, 5);
L = 3;
P = I([1 1:4 4], [1 1:5 5]);
Z = zeros(L*(4+1)+1, L*(5+1)+1);
Z(1:L:end, 1:L:end) = P;
f = 1-abs(-2:2)/3;
full2d = conv2(Z, f(:)*f(:).', 'same');
ref = full2d(L+(1:L*4), L+(1:L*5));
checks(end+1) = check('Separable convolution versus full 2D convolution', ...
    bilinear_upsample_conv(I, L), ref, tol);

Y = bilinear_upsample_conv([0 255; 255 0], 3);
violation = max([0; -Y(:); Y(:)-255]);
checks(end+1) = check('No overshoot for checkerboard input', violation, 0, tol);

fprintf('Validation: %d/%d tests PASS (tolerance %.1e).\n', ...
    nnz([checks.passed]), numel(checks), tol);
end

function result = check(name, actual, expected, tol)
assert(isequal(size(actual), size(expected)), '尺寸错误：%s', name);
err = max(abs(actual(:)-expected(:)));
passed = err <= tol;
fprintf('  %-60s error = %.3g  %s\n', name, err, string(passed));
assert(passed, '验证失败：%s，最大误差 %.6g', name, err);
result = struct('name', name, 'max_abs_error', err, 'passed', passed);
end
