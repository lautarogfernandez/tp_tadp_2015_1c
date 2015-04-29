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
    multimetodo(nombre_metodo).mapa_definiciones()
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
         self.instance_exec *args, &partial_block.bloque
         # no me gusta de esta opcion que abre la posibilidad de ejecutar el partial block sin el mathchs.
         # El tema uqe para solucionarlo habria que usar el matches adentro dle nuevo call_with_binding (llamandose 2 veces al matches)
         # partial_block.call_with_binding(*args, self)
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
  
  # def respond_to?(*argv)
  #   responde=false
  #
  #   if super.respond_to?(*argv)
  #    responde=true
  #   else
  #
  #  responde= @mapa_multi_methods.any?{|(nombre, partialblock)| nombre.eql? argv[0] and partialblock.lista_tipos_parametros.eql? argv[2]}
  #   end
  #   responde
  # end
end

class Object

  def partial_def (nombre,lista_parametros,&bloque)
    self.singleton_class.partial_def(nombre,lista_parametros,&bloque)
  end

end
