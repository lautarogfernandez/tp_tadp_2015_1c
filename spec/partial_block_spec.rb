require 'rspec'
require_relative '../src/partial_block'

describe 'Tests de PartialBlock' do

  it 'La cantidad de parametros no coinciden con la cantidad del declarada en el bloque y lanza excepcion' do

    expect{helloBlock = PartialBlock.new([Integer,String]) do |who|
      "Hello #{who}" end
    }.to raise_error(ArgumentError)#ver con excepcion lanzada

  end

  it 'La cantidad de parametros coinciden con la cantidad del declarada en el bloque' do
    helloBlock = PartialBlock.new([Integer,String]) do |who, who2|
      "Hello #{who} #{who2}"
    end

    expect(helloBlock.lista_tipos_parametros).to include(Integer,String)
  end

  it 'El tipo de parametros no coincide con el argumento recibido y lanza excepcion' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches(1)).to be (false)
  end

  it 'La cantidad de parametros no coincide con el argumentos recibido y lanza excepcion' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches("a", "b")).to be (false)
  end

  it 'La cantidad de parametros y los tipos coinciden' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches("a")).to be (true)
  end

end