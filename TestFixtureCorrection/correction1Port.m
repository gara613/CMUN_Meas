% function Z = correction1Port(GammaM,freqs,Z0,lista,dibuja,type)
%
% Rutina para corregir errores de medici�n de un puerto a partir del modelo
% de error de tres t�rminos descrito en la nota de aplicaci�n de Agilent:
% "Network Analyzer Error Models and Calibration Methods".
%
% Entradas: 
%   - GammaM: 3 x Nfreqs, Matriz de mediciones de par�metros S de los est�ndares de calibraci�n Open, Short y Load
%   - freqs: frecuencias de muetreo para la gr�fica
%   - Z0: Impedancia caracter�stica
%   - lista: CELL ARRAY con las rutas a los archivos que se van a corregir
%   - dibuja: bandera (opcional) para solicitar la gr�fica de la impedancia de los elementos medidos
%   - type: 'R', 'L', o 'C', cadena (opcional) para indicar el tipo de elemento
% 
% Salida:
%   - Z: Nmeas x Nfreqs, Matriz con las impedancias corregidas 
%
% GammaM = Ceficiente de reflexi�n medido.
% GammaC = Ceficiente de reflexi�n corregido: 
% Relaci�n:
% GammaC = (GammaM - e00) / (GammaM*e11 - Deltae);
%
% Sistema de ecuaciones para resolver las variables de error a partir de 
% tres mediciones y tres Gamma conocidas:
% e00 + Gamma1*GammaM1*e11 - Gamma1*Deltae = GammaM1;
% e00 + Gamma2*GammaM2*e11 - Gamma2*Deltae = GammaM2;
% e00 + Gamma3*GammaM3*e11 - Gamma3*Deltae = GammaM3;

function Z = correction1Port(GammaM,freqs,Z0,lista,dibuja,type)
if (~exist('dibuja', 'var'))
    dibuja = false;
	type = 'none';
elseif (~exist('type', 'var'))
    type = 'none';
end
nfreqs = size(GammaM,2);
%% Coeficientes de reflexi�n ideales de las referencias
gammaI_Open = ones(1,nfreqs);
gammaI_Short = -ones(1,nfreqs);
gammaI_Load = 1e-8*ones(1,nfreqs);% no se supone adaptaci�n perfecta por la tolerancia num�rica

%% Inicializaci�n de las matrices de correcci�n
E = zeros(3,nfreqs );
A = ones(3,3,nfreqs );

A(1,2,:) = gammaI_Open.*GammaM(1,:);
A(2,2,:) = gammaI_Short.*GammaM(2,:); 
A(3,2,:) = gammaI_Load.*GammaM(3,:);
A(1,3,:) = -gammaI_Open; 
A(2,3,:) = -gammaI_Short; 
A(3,3,:) = -gammaI_Load;

%% Par�metros de correcci�n para cada punto de frecuencia
for cont = 1:length(freqs)
    E(:,cont) = A(:,:,cont)\GammaM(:,cont);
end

%% verificar que el comportamiento sea el esperado para los est�ndares de referencia
verificaRefs = false; % variable de debug
if verificaRefs 
    % Correcci�n para medidas de referencia 
    gammaC_Open = (GammaM(1,:) - E(1,:)) ./ (GammaM(1,:).*E(2,:) - E(3,:));
    Z_Open = Z0 * (1 + gammaC_Open) ./ (1 - gammaC_Open);
    gammaC_Short = (GammaM(2,:) - E(1,:)) ./ (GammaM(2,:).*E(2,:) - E(3,:));
    Z_Short = Z0 * (1 + gammaC_Short) ./ (1 - gammaC_Short);
    gammaC_Load = (GammaM(3,:) - E(1,:)) ./ (GammaM(3,:).*E(2,:) - E(3,:));
    Z_Load = Z0 * (1 + gammaC_Load) ./ (1 - gammaC_Load);

    figure, plot(freqs, abs(gammaC_Short), freqs, abs(GammaM(2,:)));
    title('Coef refl Corto'), xlabel('freq'), ylabel('mag'); legend('Correcci�n','Medici�n');
    figure, plot(freqs, real(Z_Short), freqs, imag(Z_Short));
    title('Z Short'), xlabel('freq'), ylabel('mag'); legend('Real','Imag');

    figure, plot(freqs, abs(gammaC_Open), freqs, abs(GammaM(1,:)));
    title('Coef refl Abierto'), xlabel('freq'), ylabel('mag'); legend('Correcci�n','Medici�n');
    figure, plotyy(freqs, real(Z_Open), freqs, imag(Z_Open));
    title('Z Open'), xlabel('freq'), ylabel('mag'); legend('Real','Imag');

    figure, plot(freqs, abs(gammaC_Load), freqs, abs(GammaM(3,:)));
    title('Coef refl Carga'), xlabel('freq'), ylabel('mag'); legend('Correcci�n','Medici�n');
    figure, plot(freqs, real(Z_Load), freqs, imag(Z_Load));
    title('Z Load'), xlabel('freq'), ylabel('mag'); legend('Real','Imag');
end

Z = zeros(length(lista),nfreqs);
%% Correcciones de las mediciones
for cont = 1:length(lista)
    [gammaM, freq, ~] = readSpars(lista{cont});	
    gammaC = (squeeze(gammaM).' - E(1,:)) ./ (squeeze(gammaM).'.*E(2,:) - E(3,:));
    Z(cont,:) = Z0 .* (1 + gammaC) ./ (1 - gammaC);
    if dibuja                    
        figure, plotyy(freq, real(Z(cont,:)), freq, imag(Z(cont,:)));
		title(['Z' lista{cont}]), xlabel('freq (Hz)'), ylabel('mag'); legend('Real','Imaginario');
        switch type % no se hace extracci�n de modelo, se suponen elementos ideales
            case 'R' % resistores
                figure, plot(freq, real(Z(cont,:)));
                title(['R ' lista{cont}]), xlabel('freq (Hz)'), ylabel('Resistencia (\Omega)');
            case 'C' % capacitores
                figure, plot(freq, -1./(2*pi*freq'.*imag(Z(cont,:))));
                title(['C ' lista{cont}]), xlabel('freq (Hz)'), ylabel('Capacitancia (F)');
            case 'L' % inductores
                figure, plot(freq, imag(Z(cont,:))./(2*pi*freq'));
                title(['L ' lista{cont}]), xlabel('freq (Hz)'), ylabel('Inductancia (H)');
            case 'none' % ning�n dispositivo especificado
            otherwise 
                warning('Tipo de elemento no soportado');
        end
    end
end