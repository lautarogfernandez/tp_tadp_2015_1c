require 'rspec'
require_relative '../src/new_multi_methods'
require_relative '../src/partial_block'

describe 'Tests de MultiMethods' do

  context "4ª Punto - Base" do

    before(:each) do

      class M
        partial_def :m, [Object] do |o|
          "A>m"
        end
        partial_def :m_sin_parametros, [] do
          "Primero m_sin_parametros de M"
        end
      end
      class N < M
        partial_def :m, [Integer] do |i|
          base.m([Numeric], i) + " => B>m_integer(#{i})"
        end
        partial_def :m, [Numeric] do |n|
          base.m([Object], n) + " => B>m_numeric"
        end

        partial_def :m_sin_parametros, [Numeric] do |n|
          base.m_sin_parametros([]) + " => m_sin_parametros de N recibe #{n}"
        end
      end

    end

    it 'Prueba base con el ejemplo del TP' do
      expect(N.new.m(1)).to eq("A>m => B>m_numeric => B>m_integer(1)")
    end

    it 'Prueba base usando un tipo que no existe tal cual en el multimethod' do
      class N < M
        partial_def :m, [String] do |i|
          base.m([Fixnum], 2) + " => B>m_integer(#{i})"
        end
      end

      expect{N.new.m("lala")}.to raise_error(ArgumentError, 'Ningun partial method fue encontrado con la lista de tipos <[Fixnum]> referida en la key base')
    end

    it 'Prueba base usando un metodo sin parametros' do
      expect(N.new.m_sin_parametros(3)).to eq("Primero m_sin_parametros de M => m_sin_parametros de N recibe 3")
    end

  end

  context "5ª Punto - Base como se usa Super" do

    before(:each) do
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
        attr_accessor :neutralizado

        def initialize
          @neutralizado=false
        end

        def neutralizate
          self.neutralizado=true
        end

      end

      class Tanque
        attr_accessor :vida, :velocidad

        def initialize
          @vida = 100
          @velocidad=40
        end

        def kilometros_recorridos(horas)
          horas*self.velocidad
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
          radar.neutralizate()
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
          base.ataca_a([Soldado], soldado)
          "El soldado fue atacado levemente como si lo ataco un tanque, #{mensaje}"
        end

        partial_def :cantidad_soldados_que_puede_transportar, [Soldado] do |tripulante|
          base_posta(tripulante) + 5
        end

      end

      class PanzerTuneado < Tanque

        partial_def :cantidad_soldados_que_puede_transportar, [Soldado] do |tripulante|
          base_posta(tripulante) + 20
        end

      end


      class A
        partial_def :m, [Object] do |o|
          " => A>m"
        end
      end

      class B < A
        partial_def :m, [Integer] do |i|
          base_posta(i) + " => B>m_integer(#{i})"
        end

        partial_def :m, [Numeric] do |n|

          lala(1) + base_posta(n) + " => B>m_numeric"
        end

        partial_def :lala, [Integer] do |i|
           asd + base_posta(i) + " => B>lala_Integer(#{i})"

        end

        partial_def :lala, [Numeric] do |n|
          " => B>lala_numeric"
        end

        partial_def :asd, [] do
          pepe + " => B>asd_empty"
        end

        def pepe
          "B>pepe"
        end

      end

    end


    it 'Test base_poosta anidados (ejemplo TP)' do
      expect(B.new.m(1)).to eq("B>pepe => B>asd_empty => B>lala_numeric => B>lala_Integer(1) => A>m => B>m_numeric => B>m_integer(1)")
    end

    it 'Test base_posta lanza exception cuando no puede subir mas' do
      class A
        partial_def :m, [Object] do |o|
          base_posta(o) + "A>m"
        end
      end

      expect{B.new.m(1)}.to raise_error(ArgumentError, "No se puede aplicar base_posta porque es el partial method mas alto de la jerarquia para este tipo de parametro [Object]" )
    end

    it 'Metodo parcial sigue funcionando con base del punto 4' do
      soldado = Soldado.new
      panzer = Panzer.new()
      mensaje_amenazante = panzer.ataca_a(soldado, "la proxima esta caput")

      expect(mensaje_amenazante).to eq("El soldado fue atacado levemente como si lo ataco un tanque, la proxima esta caput")
      expect(soldado.vida).to eq(50)
    end

    # it 'Metodo parcial funciona con base_posta' do
    #   soldado = Soldado.new
    #   panzer = Panzer.new()
    #   expect(panzer.cantidad_soldados_que_puede_transportar(soldado)).to eq(15)
    # end
    #
    # it 'Metodo parcial funciona con base_posta con invocaciones anidadas' do
    #   soldado = Soldado.new
    #   panzer = PanzerTuneado.new()
    #   expect(panzer.cantidad_soldados_que_puede_transportar(soldado)).to eq(35)
    # end

  end

  context "2ª Punto - Multimethods" do

    before(:each)do
      class A
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

    end

    it 'Prueba del calculo de la distancia parcial' do
      expect(3.distancia_parametro_parcial(Numeric)).to eq(2)
      expect((3.0).distancia_parametro_parcial(Numeric)).to eq(1)
    end

    it 'Prueba del calculo de la distancia total' do
      tipos_1=[Numeric, Integer]
      tipos_2=[Integer, Integer]
      tipos_3=[Integer, Integer,Integer, Integer,Integer, Integer]
      parametros_1=[3.0, 3]
      parametros_2=[3, 3]
      parametros_3=[3,3,3,3,3,3]
      bloque_parcial_1=PartialBlock.new(tipos_1) {|a,b|}
      bloque_parcial_2=PartialBlock.new(tipos_1) {|a,b|}
      bloque_parcial_3=PartialBlock.new(tipos_2) {|a,b|}
      bloque_parcial_4=PartialBlock.new(tipos_3) {|a,b,c,d,e,f|}

      expect(bloque_parcial_1.distancia_parametro_total(parametros_1)).to eq(3)
      expect(bloque_parcial_2.distancia_parametro_total(parametros_2)).to eq(4)
      expect(bloque_parcial_3.distancia_parametro_total(parametros_2)).to eq(2)
      expect(bloque_parcial_4.distancia_parametro_total(parametros_3)).to eq(6)
    end

    it 'Probando respond_to?' do
      A.partial_def :concat, [String, Integer] do |s1,n|
        s1 * n
      end
      A.partial_def :concat, [Object, Object] do |o1, o2|
        "Objetos concatenados"
      end

      instancia_con_partial_def =A.new()
      instancia_con_partial_def.partial_def :lala, [String] do |mensaje|
        mensaje
      end

      expect(A.new.respond_to?(:concat)).to be(true)
      expect(A.new.respond_to?(:to_s)).to be(true)
      expect(A.new.respond_to?(:concat,false,[String, Integer])).to be (true)
      expect(A.new.respond_to?(:concat,false,[String, Integer,String])).to be (false)
      expect(A.new.respond_to?(:concat, false, [String,String])).to be (true) # true, define el método como multimethod
      expect(A.new.respond_to?(:concat, false, [Integer,A])).to be (true)# true, matchea con [Object, Object]
      expect(A.new.respond_to?(:concat, false, [String,String,String])).to be (false) # false, los tipos no coinciden)
      expect(A.new.respond_to?(:to_s, false, [String])).to be (false)
      expect(instancia_con_partial_def.respond_to?(:lala)).to be (true)
      expect(instancia_con_partial_def.respond_to?(:lala, false, [String])).to be (true)
      expect(instancia_con_partial_def.respond_to?(:lala, false, [Integer])).to be (false)
    end

    it 'Prueba del metodo multimethods' do
      class GG
      end
      GG.partial_def :saludar, [String] do |nombre|
        "Como va #{nombre}?"
      end
      GG.partial_def :gritar, [] do ||
        "AHHHHHHHHHHHHHHH!!!!!!"
      end
      multi=GG.multimethods()
      expect(GG.multimethods()).to include (:saludar)
      expect(GG.multimethods().size).to be (2)
      GG.partial_def :saludar, [String,Integer] do |nombre, numero|
        "Hola, #{nombre}, Boca salió #{numero} a 0"
      end
      expect(GG.multimethods()).to include (:saludar)
      expect(GG.multimethods().size).to be (2)
      GG.partial_def :decir_algo, [String] do |algo|
        "Digo #{algo}"
      end
      expect(GG.multimethods()).to include (:saludar)
      expect(GG.multimethods().size).to be (3)
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

    it 'Devuelve error si se no coincide el tipo de argumento' do
      saludador = Saludador.new()
      error_ejecucion="Los argumentos no coincide con el tipo requerido por el bloque"
      expect{saludador.saludar(5)}.to raise_error (StandardError)
    end

    it 'Devuelve error si se no coincide la cantidad de argumentos' do
      saludador = Saludador.new()
      expect{saludador.saludar("asd",5,123)}.to raise_error (StandardError)
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

  end

  context "3ª Punto - Herencia" do

    before(:each) do
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
        attr_accessor :neutralizado

        def initialize
          @neutralizado=false
        end

        def neutralizate
          self.neutralizado=true
        end

      end

      class Tanque
        attr_accessor :vida, :velocidad

        def initialize
          @vida = 100
          @velocidad=40
        end

        def kilometros_recorridos(horas)
          horas*self.velocidad
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
          radar.neutralizate()
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
          base_posta(tripulante) + 5
        end

      end

      class AA
        partial_def :m, [String] do |s|
          "metodo :m de AA"
        end
        partial_def :aa, [Numeric] do |n|
          "metodo :aa de AA"
        end
        partial_def :mm, [Object] do |o|
          "metodo :mm de AA"
        end
      end

      class Y <AA
        partial_def :m, [String] do |s|
          "A>m #{s}"
        end
        partial_def :m, [Numeric] do |n|
          "A>m" * n
        end
        partial_def :m, [Object] do |o|
          "A>m and Object"
        end
      end

      class Z < Y
        partial_def :m, [Object] do |o|
          "B>m and Object"
        end
      end

      class W < Z
        partial_def :n, [Object] do |o|
          "NNN"
        end

        partial_def :o, [Object] do |o|
          "OOO"
        end

        partial_def :o, [Integer] do |number|
          "O" * number
        end
      end

    end

    it 'Metodo Multimethods agrega los multimetodos heredados' do
      (W.multimethods(false).should match_array([:o,:n]))
      (W.multimethods(true)).should match_array([:m,:n,:o,:aa,:mm])
    end

    it 'Subclase puede acceder a multimethod heredado' do
      soldado = Soldado.new
      Panzer.new().ataca_con_ametralladora(soldado)
      expect(soldado.vida).to eq(60)
    end

    it 'Metodo normal debe sobreescribir un multimethod heredado' do
      clase_panzer=Panzer.new().class
      clase_panzer.send(:define_method,:ataca_con_ametralladora) do |soldado|
        soldado.sufrir_danio(65)
      end

      panzer=clase_panzer.new()
      soldier=Soldado.new()
      panzer.ataca_con_ametralladora(soldier)
      expect(soldier.vida).to be (35)
    end

    it 'Metodo multimethod debe sobreescribir metodo normal heredado' do
      clase_panzer=Panzer.new().class
      expect(clase_panzer.new().kilometros_recorridos(1)).to be(40)

      clase_panzer.partial_def :kilometros_recorridos,[Integer] do |horas|
        (self.velocidad*horas) + 10
      end

      expect(Tanque.new().kilometros_recorridos(1)).to be(40)
      expect(clase_panzer.new().kilometros_recorridos(1)).to be(50)
    end

    it 'Metodo multimethod debe sobreescribir metodo multimethod heredado' do
      soldado = Soldado.new
      panzer = Panzer.new()
      panzer.ataca_a(soldado)
      expect(soldado.vida).to eq (50)
    end

    it 'Metodo parcial complementa un multimehod heredado' do
      expect(Panzer.new().class.obtener_definiciones_parciales_aplicables_a_clase_actual(:ataca_a).keys.to_s).to eq("[[Tanque], [Soldado], [Radar], [Soldado, String]]")
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

    it 'Prueba herencia con el ejemplo del TP' do
      z = Z.new
      expect(z.m("hello")).to eq("A>m hello")
      expect(z.m(Object.new)).to eq("B>m and Object")
    end

  end

end