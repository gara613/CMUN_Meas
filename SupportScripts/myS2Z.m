% [Z] = function myS2Z(S, Z0) 
% Rutina para convertir par�metros S a Z
% Recibe la matriz de par�metros S (Spars entregada por la rutina readSpars) para cada una de las frecuencias 
% Se asume que la impedancia caracter�stica es independiente de la frecuencia
%
% Germ�n Augusto Ram�rez Arroyave
% CMUN - 2017
function [Z] = myS2Z(S, Z0)

    narginchk(1,2)
    if nargin < 2
        Z0 = 50;
    end
    if any(Z0 == 0)
        error('The characteristic impedance cannot be zero');
    end
    nports = size(S,1);
	Z = zeros(size(S));
%    Z0 = Z_ref*eye(totN_ports);
%    G0 = 1/Z_ref*eye(totN_ports);

    if nports == 2
        S11 = deal(S(1,1,:));	S12 = deal(S(1,2,:));
        S21 = deal(S(2,1,:));   S22 = deal(S(2,2,:));

        den = (1-S11).*(1-S22)-S12.*S21;

        Z(1,1,:) = Z0*( (1+S11).*(1-S22) + S12.*S21 ) ./den;
        Z(1,2,:) = Z0*2*S12 ./den;
        Z(2,1,:) = Z0*2*S21 ./den;
        Z(2,2,:) = Z0*( (1-S11).*(1+S22) + S12.*S21 ) ./den;
    else 
        if isscalar(Z0)
            Z0 = Z0*eye(nports);
        end
        for cont = 1:size(S,3)
            %Z(:,:,cont) = G0\ (eye(nports) - S(:,:,cont))\ (S(:,:,cont)*Z0 + conj(Z0)) *G0;   %   I'm not sure why this is giving wrong result with '\' intead of 'inv' 
            Z(:,:,cont) = Z0* inv(eye(nports) - S(:,:,cont))* (S(:,:,cont) + eye(nports));
        end
    end
return 