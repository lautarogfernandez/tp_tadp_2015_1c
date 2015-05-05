require_relative '../src/partial_block'

class Multimetodo

  attr_accessor :simbolo, :mapa_definiciones

  def initialize(simbolo,partial_block)
    @simbolo=simbolo
    @mapa_definiciones=Hash.new
    @mapa_definiciones[partial_block.lista_tipos_parametros]=partial_block
  end

  def simbolo
    @simbolo
  end

  def mapa_definiciones
    @mapa_definiciones
  end

  def sos?(nombre_metodo)
    simbolo==nombre_metodo
  end

  def agrega_definicion(partial_block)
    mapa_definiciones[partial_block.lista_tipos_parametros]=partial_block
  end

end


module MultiMethods

  attr_accessor :multimethodos

  def initialize()
    @multimetodos=Array.new
  end

  def multimetodos
    @multimetodos = @multimetodos || [] #Hash.new{ |nombre_metodo,tipos| nombre_metodo[tipos] = Hash.new}
  end

  def tiene_multimethod?(nombre_metodo)
    multimetodos.any?{|multimetodo|multimetodo.sos?(nombre_metodo)}
  end

  def multimetodo(nombre_metodo)
    multimetodos.select{|multimetodo|multimetodo.sos?(nombre_metodo)}.first()
  end

  def agregar_a_lista_de_multimethods(nombre_metodo, partial_block)
    if(self.tiene_multimethod?(nombre_metodo))
      multimetodo(nombre_metodo).agrega_definicion(partial_block)
    else
      nuevo_multimetodo=Multimetodo.new(nombre_metodo,partial_block)
      multimetodos << nuevo_multimetodo
    end
  end

  def distancia_parametro_parcial(parametro,tipo_parametro)
    parametro.class.ancestors.index(tipo_parametro)
  end

  def distancia_parametro_total(lista_parametros,lista_tipos_parametro)
    lista_parametros.collect { |parametro| distancia_parametro_parcial(parametro,lista_tipos_parametro[lista_parametros.index(parametro)])*(lista_parametros.index(parametro)+1) }.reduce(0, :+)
  end

  def obtener_multimethods_en_esta_clase(nombre_metodo)
    if  tiene_multimethod?(nombre_metodo)
      mapa_definiciones = multimetodo(nombre_metodo).mapa_definiciones()
    else
      mapa_definiciones = {}
    end
    mapa_definiciones
  end

  def tiene_multimethod?(nombre_metodo)
    multimetodos.any?{|multimetodo|multimetodo.sos?(nombre_metodo)}
  end

  def obtener_definiciones_parciales_aplicables_a_clase_actual(nombre_metodo, definiciones_parciales = {})
    resultado = obtener_multimethods_en_esta_clase(nombre_metodo).merge(definiciones_parciales)
    proximo_ancestor = self.ancestors[1]
    if( proximo_ancestor.tiene_multimethod?(nombre_metodo) )
      resultado = proximo_ancestor.obtener_definiciones_parciales_aplicables_a_clase_actual(nombre_metodo, resultado)
    end

    resultado
  end

  def obtener_multimethod_a_ejecutar(metodo_ejecutado, argumentos)
    definiciones_parciales = obtener_definiciones_parciales_aplicables_a_clase_actual(metodo_ejecutado)
    todos_los_que_matchean = definiciones_parciales.select { |lista_parametros, partial_block| partial_block.matches(*argumentos)}
    if(todos_los_que_matchean.empty?)
      raise(StandardError)
    else
      multimethod_a_ejecutar =todos_los_que_matchean.sort_by{|tipos_params_1,partial_block_1|(-1)* distancia_parametro_total(argumentos,tipos_params_1)}.reverse[0][1]
      multimethod_a_ejecutar
    end
  end

  def partial_def (nombre,lista_parametros,&bloque)
    partial_block = PartialBlock.new(lista_parametros,&bloque)
    agregar_a_lista_de_multimethods(nombre, partial_block)

    if(!self.respond_to?(nombre))
      class_up = self
      self.send(:define_method,nombre) do |*args|
         partial_block = class_up.obtener_multimethod_a_ejecutar(__method__, args)
         #self.instance_exec *args, &partial_block.bloque
         # no me gusta de esta opcion que abre la posibilidad de ejecutar el partial block sin el mathchs.
         # El tema uqe para solucionarlo habria que usar el matches adentro dle nuevo call_with_binding (llamandose 2 veces al matches)
         partial_block.call_with_binding(*args, self)
      end
    end
  end

  def multimethods()
    self.multimetodos.collect{|multimetodo|multimetodo.simbolo}
  end

  def multimethod(nombre_metodo)
    if (self.tiene_multimethod?(nombre_metodo))
      self.multimetodo(nombre_metodo).mapa_definiciones()
    else
      false #no me deja tirar exepcion
    end
  end

end

class Module
  include MultiMethods
end


class Base
  attr_accessor :selfie

  def initialize(selfie)
    @selfie = selfie
  end
end

class Object

  def partial_def (nombre,lista_parametros,&bloque)
    self.singleton_class.partial_def(nombre,lista_parametros,&bloque)
  end

  alias_method :respond_to_original?, :respond_to?

  def respond_to?(*argv)
    responde = false

    if((argv.length.eql? 1) || (argv.length.eql? 2))
      responde= self.respond_to_original?(*argv) # TODO con el super(*args) que onda??
    else
      metodo = argv[0]
      tipos_parametros = argv[2]

      responde = obtener_definiciones_parciales_aplicables_a_instancia(self, metodo).any?  do |lista_parametros, partial_block|
        partial_block.matches_tipos(tipos_parametros)
      end
    end
    responde
  end

  def obtener_definiciones_parciales_aplicables_a_instancia(instancia, metodo)
    instancia.singleton_class.obtener_definiciones_parciales_aplicables_a_clase_actual(metodo)
  end


  def method_missing(metodo, *args)
    if(self.is_a?(Base))

      lista_de_tipos_del_multi_method = args.delete_at(0)
      lista_de_argumentos_del_multi_method = args
      instancia = self.selfie

      ejecutar_metodo_con_base(instancia, metodo, lista_de_tipos_del_multi_method, lista_de_argumentos_del_multi_method)

    elsif(metodo.equal?(:base))
      Base.new(self)

    elsif(metodo.equal?(:base_posta))

      ejecutar_base_posta_obteniendo_metodo_por_file(self, args)

    else
      super(metodo, *args)
    end

  end

  def ejecutar_metodo_con_base(instancia, metodo, lista_de_tipos_del_multi_method, lista_de_argumentos_del_multi_method)

    definiciones_parciales = obtener_definiciones_parciales_aplicables_a_instancia(instancia, metodo)

    if definiciones_parciales.has_key?(lista_de_tipos_del_multi_method)
      bloque_parcial = definiciones_parciales[lista_de_tipos_del_multi_method]
      bloque_parcial.call_with_binding(*lista_de_argumentos_del_multi_method, instancia)

      #instancia.instance_exec *lista_de_argumentos_del_multi_method, &definiciones_parciales[lista_de_tipos_del_multi_method].bloque
    else
      raise ArgumentError, 'Ningun partial method fue encontrado con esa lista de tipos referida en la key base'
    end

  end

  def ejecutar_base_posta_obteniendo_metodo_por_file(instancia, args)
    file_line= caller.select{|line| line.include?("block in <class:#{instancia.class}>")}.first.split(':')[0,2]
    file_path = file_line[0]
    file_line = file_line[1].to_i

    while file_line > 0
      line_string = IO.readlines(file_path)[file_line]
      if(line_string.include?("partial_def"))
        line_with_method_name = line_string
        break
      end
      file_line = file_line - 1
    end
    metodo_obtenido = line_with_method_name.split(',')[0].split(' ')[1].gsub!(':','').to_sym
    bloque_parcial = instancia.class.ancestors[1].obtener_multimethod_a_ejecutar(metodo_obtenido, args)

    #instancia.instance_exec *args, &bloque_parcial.bloque
    bloque_parcial.call_with_binding(*args, instancia)
  end

end
