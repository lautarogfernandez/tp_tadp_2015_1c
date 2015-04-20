require 'rspec'
require_relative '../src/multi_methods'
require_relative '../src/partial_block'

describe 'Tests de MultiMethods' do

  #me parece que hay que incluir el modulo en la clase CLASS
  class A
    include MultiMethods
  end

  it 'Prueba del calculo de la distancia parcial' do
    calculo=A.new()
    expect(calculo.distancia_parametro_parcial(3,Numeric)).to eq(2)
    expect(calculo.distancia_parametro_parcial(3.0,Numeric)).to eq(1)
  end

  it 'Prueba del calculo de la distancia total' do
    calculo=A.new()
    tipos_1=[Numeric, Integer]
    tipos_2=[Integer, Integer]
    tipos_3=[Integer, Integer,Integer, Integer,Integer, Integer]
    parametros_1=[3.0, 3]
    parametros_2=[3, 3]
    parametros_3=[3,3,3,3,3,3]
    expect(calculo.distancia_parametro_total(parametros_1,tipos_1)).to eq(3)
    expect(calculo.distancia_parametro_total(parametros_2,tipos_1)).to eq(4)
    expect(calculo.distancia_parametro_total(parametros_2,tipos_2)).to eq(2)
    expect(calculo.distancia_parametro_total(parametros_3,tipos_3)).to eq(6)
  end

  it 'Prueba de definicion parcial de un metodo unico' do
    A.partial_def :concat, [String, Integer] do |s1,n|
        s1 * n
    end
    expect(A.new().concat("Hello", 2)=="HelloHello").to be(true)
  end

  it 'Prueba de definicion parcial de dos metodos con la misma firma' do
    A.partial_def :concat, [String, Integer] do |s1,n|
      s1 * n
    end
    partial_def :concat, [Object, Object] do |o1, o2|
      "Objetos concatenados"
    end
    expect(A.new.concat(Object.new, 3)=="Objetos concatenados").to be(true)
  end

end