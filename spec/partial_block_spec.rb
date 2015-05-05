require 'rspec'
require_relative '../src/partial_block'

describe 'Tests de PartialBlock' do

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

    # helloBlockSinParametros = PartialBlock.new() do
    #   "Hello"
    # end

    expect(helloBlockConArrayVacio.lista_tipos_parametros).to be_empty
    #pending(helloBlockSinParametros.lista_tipos_parametros).to be_empty
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
    module Mod_B
      def mostrar
        "a"
      end
    end

    clase_b = class Clas_B
      include Mod_B
    end

    helloBlock = PartialBlock.new([Clas_B, Mod_B]) do |arg1, arg2|
      arg1.mostrar
    end

    instancia_b = clase_b.new()

    expect(helloBlock.matches(instancia_b, instancia_b)).to be (true)
    expect(helloBlock.matches(instancia_b, "a")).to be (false)
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
    helloBlock = PartialBlock.new([Object, Integer]) do |arg1, arg2|
      "Hello #{arg1} #{arg2.to_s}!!!"
    end

    expect(helloBlock.matches("world", 2)).to be (true)
    expect(helloBlock.call("world", 2)).to eq ("Hello world 2!!!")
  end

  it 'Se puede ejecutar un partial block con call usando argumentos que son submodulos de los tipos' do
    module Mod_A
      def mostrar
        "a"
      end
    end

    clase_a = class Clas_A
      include Mod_A
    end

    helloBlock = PartialBlock.new([Clas_A, Mod_A]) do |arg1, arg2|
      arg1.mostrar
    end

    instancia_a = clase_a.new()

    expect(helloBlock.matches(instancia_a, instancia_a)).to be (true)
    expect(helloBlock.call(instancia_a, instancia_a)).to eq ("a")
  end

  it 'Crear un partial block pasandole los argumentos incorrectamente y lanza un Argumment Exception' do
    error_creacion= "No coincide la aridad del bloque con la cantidad de parametros"

    expect{
        new_block_1 = PartialBlock.new([]) do |who|
          "Hello #{who}"
        end}.to raise_error(ArgumentError, error_creacion)
    expect{
        new_block_2 = PartialBlock.new([Integer,String]) do |who|
          "Hello #{who}"
        end}.to raise_error(ArgumentError, error_creacion)
    expect{
        new_block_3 = PartialBlock.new([Integer,String]) do |who, a, b,c|
          "Hello #{who}"
        end}.to raise_error(ArgumentError, error_creacion)
    end

  it 'Ejecutar un partial block con call pasandole los argumentos incorrectos lanza un Argumment Exception' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end
    error_ejecucion="Los argumentos no coincide con el tipo requerido por el bloque"

    expect{helloBlock.call()}.to raise_error.with_message(error_ejecucion)
    expect{helloBlock.call([])}.to raise_error.with_message(error_ejecucion)
    expect{helloBlock.call(1)}.to raise_error.with_message(error_ejecucion)
    expect{helloBlock.call(Object.new())}.to raise_error.with_message(error_ejecucion)
    expect{helloBlock.call("world!","world2")}.to raise_error.with_message(error_ejecucion)
  end

end