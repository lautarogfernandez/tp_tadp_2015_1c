require_relative '../src/partial_block'

module MultiMethods

  attr_accessor :mapa_multi_methods

  def mapa_multi_methods
    @mapa_multi_methods = @mapa_multi_methods || Hash.new{ |nombre_metodo,tipos| nombre_metodo[tipos] = Hash.new}
  end

  def distancia_parametro_parcial(parametro,tipo_parametro)
    parametro.class.ancestors.index(tipo_parametro)
  end

  def distancia_parametro_total(lista_parametros,lista_tipos_parametro)
    lista_parametros.collect { |parametro| distancia_parametro_parcial(parametro,lista_tipos_parametro[lista_parametros.index(parametro)])*(lista_parametros.index(parametro)+1) }.reduce(0, :+)
  end

  def obtener_multimethods_en_esta_clase(nombre_metodo)
    mapa_multi_methods.values_at(nombre_metodo).first()
  end

  def tiene_multimethod?(nombre_metodo)
    mapa_multi_methods.has_key?(nombre_metodo)
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

  def agregar_a_lista_de_multimethods(nombre, partial_block)
    # @mapa_multi_methods[nombre] = bloque #
    mapa_multi_methods # TODO muy choto si no hacia esto no se me inicializaba el mapa de hashes
    mapa_tipos_parametros =  @mapa_multi_methods[nombre]
    mapa_tipos_parametros[partial_block.lista_tipos_parametros] = partial_block
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
    self.mapa_multi_methods.keys
  end

  def multimethod(nombre)
    if (self.mapa_multi_methods.has_key?(nombre))
      self.mapa_multi_methods.values_at(nombre)
    else
      false #no me deja tirar exepcion
    end
  end

end

class Module
  include MultiMethods
  
   def respond_to?(*argv)
     responde=false

     if argv.length.eql? 1
      responde= super.respond_to?(argv[0]) || self.tiene_multimethod?(argv[0])
     else
       responde= obtener_definiciones_parciales_aplicables_a_clase_actual(argv[0]).any?  { |lista_parametros, partial_block| partial_block.matches(*argv[2])}
     end
     responde
   end
end

class Object

  def partial_def (nombre,lista_parametros,&bloque)
    self.singleton_class.partial_def(nombre,lista_parametros,&bloque)
  end

end
