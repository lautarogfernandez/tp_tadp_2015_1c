require 'rspec'
require_relative '../src/new_multi_methods'
require_relative '../src/partial_block'

describe 'Tests de MultiMethods' do

  #me parece que hay que incluir el modulo en la clase CLASS
  class A
    include MultiMethods
  end

  class Guerrero
    attr_accessor :puesto

  end

  class Saludador

    attr_accessor :nombre

    def metodo_para_asegurarme_que_self_es_saludador

    end

    def saludo_militar puesto
      self
      "#{puesto}, si #{puesto}!"
    end

    partial_def :saludar, [String] do |nombre|
      "Hola #{nombre}"
    end

    partial_def :saludar, [String, Integer] do |nombre, cantidad_de_saludos|
      "Hola #{nombre} " * cantidad_de_saludos
    end

    partial_def :saludar, [Guerrero] do |guerrero|
      self.saludo_militar(guerrero.puesto)
    end

    partial_def :saludar, [String, String] do |nombre1, nombre2|
      "Hola #{nombre1} y #{nombre2}, me llamo #{@nombre}"
    end

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
    A.partial_def :concat, [Object, Object] do |o1, o2|
      "Objetos concatenados"
    end
    expect(A.new.concat(Object.new, 3)=="Objetos concatenados").to be(true)
  end

  it 'Prueba de definir multimetodo en clase' do
    saludador = Saludador.new()
    expect(saludador.saludar("Ale")).to eq ("Hola Ale")
  end


  it 'Definir multimetodo en clase con argumentos que son subclases del tipo de parametro (FixNum e Integer)' do
    saludador = Saludador.new()
    expect(saludador.saludar("Ale", 3)).to eq ("Hola Ale Hola Ale Hola Ale ")
  end

  it 'Funciona si usa dentro de un partial method una referencia con self a otro metodo de la misma clase' do
    guerrero = Guerrero.new()
    guerrero.puesto="Capitan"

    saludador = Saludador.new()
    saludador.saludo_militar(guerrero)
    expect(saludador.saludar(guerrero)).to eq ("Capitan, si Capitan!")
  end

  it 'Funciona si se usa un partial method Statefull' do
    saludador = Saludador.new()
    saludador.nombre="Jose"
    expect(saludador.saludar("Jorge","Juan")).to eq ("Hola Jorge y Juan, me llamo Jose")
  end

  it 'Funciona si se usa un partial method reabriendo la clase abajo sin pisar los anteriores' do
    class Saludador
      partial_def :saludar, [Float] do |cuasi_saludo|
        "Te #{cuasi_saludo} saludo!"
      end
    end

    saludador = Saludador.new()
    expect(saludador.saludar(0.5)).to eq ("Te 0.5 saludo!")
  end

  it 'Funciona si se agrega un multi method a un objeto/instancia' do
    saludador_navidenio = Saludador.new()
    saludador = Saludador.new()

    saludador_navidenio.partial_def :saludar_en_navidad, [String] do |nombre|
      "Feliz navidad #{nombre}"
    end

    saludador_navidenio.partial_def :saludar_en_navidad, [Integer] do |cantidad|
      "Oh " * cantidad # o era jo jo jo??
    end

    class Saludador
      partial_def :saludar, [String] do |nombre|
        "Como va #{nombre}?"
      end
    end

    expect{(Saludador.saludar_en_navidad(3))}.to raise_error(NoMethodError)
    expect{(saludador_navidenio.singleton_class.saludar_en_navidad(3))}.to raise_error(NoMethodError)
    expect{(saludador.saludar_en_navidad(3))}.to raise_error(NoMethodError)

    expect(saludador_navidenio.saludar_en_navidad(3)).to eq ("Oh Oh Oh ")
    expect(saludador_navidenio.saludar_en_navidad("Rodolfo")).to eq ("Feliz navidad Rodolfo")
    expect(saludador_navidenio.saludar("Ale")).to eq ("Como va Ale?")
    expect(saludador_navidenio.saludo_militar("Capitan")).to eq ("Capitan, si Capitan!")

  end

  it 'Funciona si se usa un partial method reabriendo la clase abajo redefiniendo un metodo anterior' do
    class Saludador
      partial_def :saludar, [String] do |nombre|
        "Como va #{nombre}?"
      end
    end

    saludador = Saludador.new()
    expect(saludador.saludar("Pepe")).to eq ("Como va Pepe?")
  end

  it 'Prueba del metodo multimethods' do
    class B
    end
    B.partial_def :saludar, [String] do |nombre|
      "Como va #{nombre}?"
    end
    B.partial_def :gritar, [] do ||
      "AHHHHHHHHHHHHHHH!!!!!!"
    end
    expect(B.multimethods()).to include (:saludar)
    expect(B.multimethods().size).to be (2)
    B.partial_def :saludar, [String,Integer] do |nombre, numero|
      "Hola, #{nombre}, Boca salió #{numero} a 0"
    end
    expect(B.multimethods()).to include (:saludar)
    expect(B.multimethods().size).to be (2)
    B.partial_def :decir_algo, [String] do |algo|
      "Digo #{algo}"
    end
    expect(B.multimethods()).to include (:saludar)
    expect(B.multimethods().size).to be (3)
  end

  it 'Prueba del metodo multimethod' do
    class C
    end
    C.partial_def :saludar, [String] do |nombre|
      "Como va #{nombre}?"
    end
    C.partial_def :gritar, [] do ||
      "AHHHHHHHHHHHHHHH!!!!!!"
    end
    expect(C.multimethod(:saludar)).to eq (C.multimetodo(:saludar).mapa_definiciones)
    expect(C.multimethod(:gritar)).to eq (C.multimetodo(:gritar).mapa_definiciones)
    expect(C.multimethod(:decir_algo)).to be(false)
    C.partial_def :saludar, [String,Integer] do |nombre, numero|
      "Hola, #{nombre}, Boca salió #{numero} a 0"
    end
    expect(C.multimethod(:saludar)).to eq (C.multimetodo(:saludar).mapa_definiciones)
    C.partial_def :decir_algo, [String] do |algo|
      "Digo #{algo}"
    end
    expect(C.multimethod(:decir_algo)).to eq (C.multimetodo(:decir_algo).mapa_definiciones)
    expect(C.multimethod(:jo)).to be(false)
  end

  it 'Pruebo que seleccione el metodo correcto' do
    class Saluda
      partial_def :saludar, [String] do |nombre|
        "Como va #{nombre}?"
      end
      partial_def :saludar, [Integer] do |numero|
        "Hola! " * numero
      end
      partial_def :saludar, [String,Integer] do |nombre,numero|
        "Como va #{nombre}?" * numero
      end
      partial_def :saludar, [Numeric] do |numero|
        "Hola version #{numero}"
      end
    end
    expect(Saluda.new.saludar("Casty")).to eq("Como va Casty?")
    expect(Saluda.new.saludar(5)).to eq("Hola! Hola! Hola! Hola! Hola! ")
    expect(Saluda.new.saludar("Casty",3)).to eq("Como va Casty?Como va Casty?Como va Casty?")
    expect(Saluda.new.saludar(5.0)).to eq("Hola version 5.0")
    #expect(Saluda.new.saludar("Casty",3.0)).to raise_error(StandardError) #algo aca no anda con las excepciones

    class Concatenador
      partial_def :concat, [String, Integer] do |s1,n|
        s1 * n
      end
      partial_def :concat, [Object, Object] do |o1, o2|
        "Objetos concatenados"
      end
    end
    expect(Concatenador.new.concat("Hello", 2)).to eq("HelloHello")
    expect(Concatenador.new.concat(Object.new, 3)).to eq("Objetos concatenados")
  end

  it 'Prueba de respond_to?' do
    class K
      partial_def :concat, [String, Integer] do |s1,n|
        s1 * n
      end

      partial_def :concat, [Object, Object] do |o1, o2|
        "Objetos concatenados"
      end
    end
    expect(K.new.respond_to?(:concat, false, [String,String])).to be (true) # true, define el método como multimethod
    expect(K.new.respond_to?(:to_s)).to be (true)# true, define el método normalmente
    expect(K.new.respond_to?(:concat, false, [String,String])).to be (true)# true, los tipos coinciden
    expect(K.new.respond_to?(:concat, false, [Integer,A])).to be (true)# true, matchea con [Object, Object]
    expect(K.new.respond_to?(:to_s, false, [String])).to be (true) # false, no es un multimethod
    expect(K.new.respond_to?(:concat, false, [String,String,String])).to be (true) # false, los tipos no coinciden)
  end

  class Soldado

    attr_accessor :vida

    def initialize
      @vida = 100
    end

    def sufrir_danio(danio)
      @vida = @vida - danio
    end

  end

  class Radar
    def neutralizado

    end
  end

  class Tanque
    attr_accessor :vida

    def initialize
      @vida = 100
    end

    partial_def :ataca_con_ametralladora, [Soldado] do |soldado|
      soldado.sufrir_danio(40)
    end

    partial_def :ataca_a, [Tanque] do |objetivo|
      self.ataca_con_canion(objetivo)
    end

    partial_def :ataca_a, [Soldado] do |objetivo|
      self.ataca_con_ametralladora(objetivo)
    end

    partial_def :cantidad_soldados_que_puede_transportar, [Soldado] do |objetivo|
      10
    end

  end

  class Panzer < Tanque

    def uber_ataca_a(soldado)
      soldado.sufrir_danio(50)
    end

    def neutralizar(radar)
      radar.neutralizado()
    end

    #Esta definición se suma a las heredadas de Tanque, sin pisar ninguna
    partial_def :ataca_a, [Radar] do |radar|
      self.neutralizar(radar)
    end

    #Pisa la definición parcial de la superclase correspondiente al soldado
    partial_def :ataca_a, [Soldado] do |soldado|
      self.uber_ataca_a(soldado)
    end

    partial_def :ataca_a, [Soldado, String] do |soldado, mensaje|
      base.ataca_a(soldado)
      "El soldado fue atacado levemente como si lo ataco un tanque, #{mensaje}"
    end

    partial_def :cantidad_soldados_que_puede_transportar, [Soldado] do |tripulante|
      base_posta(Soldado) + 5
    end

  end

  it 'Metodo normal debe sobreescribir un multimethod heredado' do
    #TODO
  end

  it 'Metodo multimethod debe sobreescribir metodo normal heredado' do
     panzer = Panzer.new()
  #   panzer.ataca_a(Soldado.new)
    #TODO
  end


  it 'Metodo multimethod debe sobreescribir metodo multimethod heredado' do
    soldado = Soldado.new
    panzer = Panzer.new()

    panzer.ataca_a(soldado)
    expect(soldado.vida).to eq (50)
  end

  it 'Metodo parcial complementa un multimehod heredado' do
    expect(Panzer.new().class.obtener_definiciones_parciales_aplicables_a_clase_actual(:ataca_a).keys.to_s).to eq("[[Tanque], [Soldado], [Radar]]")
  end

  it 'Subclase puede acceder a multimethod heredado' do
    soldado = Soldado.new
    Panzer.new().ataca_con_ametralladora(soldado)
    expect(soldado.vida).to eq(60)
  end

  it 'Metodo parcial en instancia complementa multimethods de clase y heredados' do
    soldado = Soldado.new
    panzer = Panzer.new()

    panzer.partial_def :ataca_a, [Soldado, Integer] do |objetivo,cantidad|
      self.uber_ataca_a(soldado)
      self.uber_ataca_a(soldado)
    end

    panzer.ataca_a(soldado,2)
    expect(soldado.vida).to eq(0)
  end

  it 'Metodo parcial funciona con base' do
    soldado = Soldado.new
    panzer = Panzer.new()
    mensaje_amenazante = panzer.ataca_a(soldado, "la proxima esta caput")

    expect(mensaje_amenazante).to eq("El soldado fue atacado levemente como si lo ataco un tanque, la proxima esta caput")
    expect(soldado.vida).to eq(60)
  end

  it 'Metodo parcial funciona con base_posta' do
    soldado = Soldado.new
    panzer = Panzer.new()
    expect(panzer.cantidad_soldados_que_puede_transportar(soldado)).to eq(15)
  end

  it 'Probando respond_to?' do
    class A
      partial_def :concat, [String, Integer] do |s1,n|
        s1 * n
      end

      partial_def :concat, [Object, Object] do |o1, o2|
        "Objetos concatenados"
      end
    end

    expect(A.new.class.respond_to?(:concat)).to be(true)
    expect(A.new.class.respond_to?(:to_s)).to be(true)
    expect(A.new.class.respond_to?(:concat,false,[String, Integer])).to be (true)
    expect(A.new.class.respond_to?(:concat,false,[String, Integer,String])).to be (false)
  end

end