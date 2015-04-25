require_relative '../src/partial_block'

module MultiMethods

  attr_accessor :mapa_multi_methods

  def mapa_multi_methods
    # @mapa_multi_methods || Hash.new # -> cambiazo por array de hashes me confunde el hash de hashes
    @mapa_multi_methods = @mapa_multi_methods || Hash.new{ |nombre_metodo,tipos| nombre_metodo[tipos] = Hash.new}
  end

  def suma(lista)#TODO:se puede agregar a la clase que corresponda en ruby
    sum = 0
    lista.each { |a| sum+=a }
    sum
  end

  def distancia_parametro_parcial(parametro,tipo_parametro)
    parametro.class.ancestors.index(tipo_parametro)
  end

  def distancia_parametro_total(lista_parametros,lista_tipos_parametro)#arreglar segun corresponda segun suma
    total =suma(lista_parametros.collect { |parametro| distancia_parametro_parcial(parametro,lista_tipos_parametro[lista_parametros.index(parametro)])*(lista_parametros.index(parametro)+1) })
  end

  def obtener_multimethod_a_ejecutar(metodo_ejecutado, argumentos)

    mapa_tipos_parametros = @mapa_multi_methods[metodo_ejecutado] if @mapa_multi_methods.key?(metodo_ejecutado) # Si ya entre aca deberia existir el metodo en el mapa pero por las ddudas

    mapa_tipos_parametros = mapa_tipos_parametros.select{|tipos_params, partial_block| partial_block.matches(*argumentos) }
    if  !mapa_tipos_parametros.empty?
      multimethod_a_ejecutar = mapa_tipos_parametros.to_a[0][1]
    else
      raise(ArgumentError)
    end

    multimethod_a_ejecutar

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

    if(!self.respond_to?(:nombre))
      self.send(:define_method,nombre) do |*args|
         partial_block =  self.class.obtener_multimethod_a_ejecutar(__method__, args)

         self.instance_exec *args, &partial_block.bloque
         #partial_block.call(*args) # TODO hmm no habria que bindearlo a self?? hay que hacer un test con un metodo statefull
      end
    end
  end
end

class Class
  include MultiMethods


  def respond_to?(*argv)
    responde=false

    if super.respond_to?(*argv)
     responde=true
    else

   responde= @mapa_multi_methods.any?{|(nombre, partialblock)| nombre.eql? argv[0] and partialblock.lista_tipos_parametros.eql? argv[2]}
    end
    responde
  end
end


