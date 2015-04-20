require 'rspec'
require_relative '../src/multi_methods'

describe 'Tests de MultiMethods' do

  it 'Prueba del calculo de la distancia parcial' do
    calculo=MultiMethods.new()
    expect(calculo.distancia_parametro_parcial(3,Numeric)).to eq(2)
    expect(calculo.distancia_parametro_parcial(3.0,Numeric)).to eq(1)
  end

  it 'Prueba del calculo de la distancia total' do
    tipos_1=[Numeric, Integer]
    tipos_2=[Integer, Integer]
    tipos_3=[Integer, Integer,Integer, Integer,Integer, Integer]
    parametros_1=[3.0, 3]
    parametros_2=[3, 3]
    parametros_3=[3,3,3,3,3,3]
    calculo=MultiMethods.new()
    expect(calculo.distancia_parametro_total(parametros_1,tipos_1)).to eq(3)
    expect(calculo.distancia_parametro_total(parametros_2,tipos_1)).to eq(4)
    expect(calculo.distancia_parametro_total(parametros_2,tipos_2)).to eq(2)
    expect(calculo.distancia_parametro_total(parametros_3,tipos_3)).to eq(6)
  end

end