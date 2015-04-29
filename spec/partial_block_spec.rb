require 'rspec'
require_relative '../src/partial_block'

describe 'Tests de PartialBlock' do

  it 'La cantidad de parametros no coinciden con la cantidad del declarada en el bloque y lanza excepcion' do

    expect{helloBlock = PartialBlock.new([Integer,String]) do |who|
      "Hello #{who}" end
    }.to raise_error(ArgumentError) #TODO 1 ver de crear una exception de negocio

  end

  it 'La cantidad de parametros coinciden con la cantidad declarada en el bloque y se crea el partial block correctamente' do
    helloBlock = PartialBlock.new([Integer,String]) do |who, who2|
      "Hello #{who} #{who2}"
    end

    expect(helloBlock.lista_tipos_parametros).to include(Integer,String)
  end

  it 'Partial block sin parametros se crea correctamente si el bloque tiene aridad 0' do
    helloBlockConArrayVacio = PartialBlock.new([]) do
      "Hello"
    end

    helloBlockSinParametros = PartialBlock.new() do
      "Hello"
    end

    expect(helloBlockConArrayVacio.lista_tipos_parametros).to be_empty
    expect(helloBlockSinParametros.lista_tipos_parametros).to be_empty
  end

  it 'El tipo de parametro no coincide con el tipo de argumento recibido. Retorna false' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches(1)).to be (false)
  end

  it 'La cantidad de parametros no coincide con los argumentos recibidos. Devuelve false' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches("a", "b")).to be (false)
  end

  it 'La cantidad de argumentos y los tipos coinciden con los tipos de parametros. Devuelve true' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches("a")).to be (true)
  end

  it 'Matches devuelve true cuando se pasan subclases de los parametros.' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches("a")).to be (true)
  end

  it 'Matches devuelve true cuando se pasan subclases de los parametros.' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches("a")).to be (true)
  end

  it 'La cantidad de parametros y los tipos coinciden y call satisfactorio' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end
    expect(helloBlock.matches("world!")).to be (true)
    expect(helloBlock.call("world!")).to eq ("Hello world!")

    otherBlock = PartialBlock.new([]) do ||
      "Hello world!"
    end
    expect(otherBlock.matches()).to be (true)
    expect(otherBlock.call()).to eq ("Hello world!")
  end

  it 'Se puede ejecutar un partial block con call sin argumentos' do
    helloBlock = PartialBlock.new([]) do
      "Hello"
    end

    expect(helloBlock.matches()).to be (true)
    expect(helloBlock.call()).to eq ("Hello")
  end


  it 'Se puede ejecutar un partial block con call usando argumentos que son subclases de los tipos' do
    helloBlock = PartialBlock.new([Object, Object]) do |arg1, arg2|
      "Hello #{arg1} #{arg2.to_s}!!!"
    end

    expect(helloBlock.matches("world", 2)).to be (true)
    expect(helloBlock.call("world", 2)).to eq ("Hello world 2!!!")
  end

  #TODO hacer test para comprobar que se puedan usar modulos en la firma

  it 'Ejecutar un partial block con call pasandole los argumentos incorrectos lanza un Argumment Exception' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect{helloBlock.call()}.to raise_error (ArgumentError)
    expect{helloBlock.call([])}.to raise_error (ArgumentError)
    expect{helloBlock.call(1)}.to raise_error (ArgumentError)
    expect{helloBlock.call(Object.new())}.to raise_error (ArgumentError)
    expect{helloBlock.call("world!","world2")}.to raise_error (ArgumentError)
  end

end