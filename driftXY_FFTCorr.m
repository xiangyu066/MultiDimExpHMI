function [shiftY,shiftX] = driftXY_FFTCorr(database0,database1)

[height,width,~] = size(database0);

A = database0;
A = abs(A);

B = database1;
B = B-mean2(B);
B = B/std2(B);
B = abs(B);

Crr = abs(ifft2(fft2(B).*conj(fft2(A))));
[shiftY,shiftX] = find(Crr==max(Crr(:)));

if isgpuarray(A)
    shiftY = gather(shiftY);
    shiftX = gather(shiftX);
end