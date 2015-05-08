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

  attr_accessor :multimetodos

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

  def obtener_multimethods_en_esta_clase(nombre_metodo)
    if  tiene_multimethod?(nombre_metodo)
      mapa_definiciones = multimetodo(nombre_metodo).mapa_definiciones()
    else
      mapa_definiciones = {}
    end
    mapa_definiciones
  end

  def obtener_definiciones_parciales_aplicables_a_clase_actual(nombre_metodo, definiciones_parciales = {})
    resultado = obtener_multimethods_en_esta_clase(nombre_metodo).merge(definiciones_parciales)
    proximo_ancestor = self.ancestors[1]
    if( proximo_ancestor.tiene_multimethod?(nombre_metodo) )
      resultado = proximo_ancestor.obtener_definiciones_parciales_aplicables_a_clase_actual(nombre_metodo, resultado)
    end

    resultado
  end

  def valido_si_existe_algun_multimethod_que_matchee(todos_los_que_matchean)
    if(todos_los_que_matchean.empty?)
      raise StandardError,"No existe el multimetohd: <#{metodo_ejecutado}> con parametros <#{argumentos.collect { |argumento| argumento.class }}>  para <#{self.class}>"
    end
  end

  def obtener_multimethod_a_ejecutar(metodo_ejecutado, argumentos, lista_tipos_llamado_base_posta = nil)
    definiciones_parciales = obtener_definiciones_parciales_aplicables_a_clase_actual(metodo_ejecutado)
    todos_los_que_matchean = definiciones_parciales.select { |lista_parametros, partial_block| partial_block.matches(*argumentos)}

    valido_si_existe_algun_multimethod_que_matchee(todos_los_que_matchean)

    definiciones_que_matchean_ordenadas = todos_los_que_matchean.sort_by{|tipos_params_1,partial_block_1| partial_block_1.distancia_parametro_total(argumentos)}

    if lista_tipos_llamado_base_posta.nil?
      multimethod_a_ejecutar = definiciones_que_matchean_ordenadas.first[1]
    else
      definiciones_correspondientes_a_base = definiciones_que_matchean_ordenadas.select do
          |definicion| definicion[1].matches_tipos(lista_tipos_llamado_base_posta)
        end

      raise ArgumentError, "No se puede aplicar base_posta porque es el partial method mas alto de la jerarquia" if definiciones_correspondientes_a_base.size < 2
      multimethod_a_ejecutar = definiciones_correspondientes_a_base[1][1]
    end

  end

  def partial_def (nombre,lista_parametros,&bloque)
    partial_block = PartialBlock.new(lista_parametros,&bloque)
    agregar_a_lista_de_multimethods(nombre, partial_block)

    if(!self.respond_to?(nombre))
      class_up = self
      self.send(:define_method,nombre) do |*args|

         partial_block = class_up.obtener_multimethod_a_ejecutar(__method__, args)

         agregar_al_stack_llamados_a_metodos(nombre, partial_block.lista_tipos_parametros, args)

         partial_block.call_with_binding(*args, self)
      end
    end
  end

  def multimethods(ver_metodos_heredados=false)
    if(ver_metodos_heredados)
      ancestros=self.ancestors.collect{|ancestor|ancestor.multimetodos}.flatten().collect{|multimetodo|multimetodo.simbolo}.uniq
    else
      self.multimetodos.collect{|multimetodo|multimetodo.simbolo}.uniq
    end
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

  def ejecutar_metodo_con_base(metodo, lista_de_tipos_del_multi_method, lista_de_argumentos_del_multi_method)

    instancia = @selfie

    definiciones_parciales = instancia.obtener_definiciones_parciales_aplicables_a_instancia(metodo)

    if definiciones_parciales.has_key?(lista_de_tipos_del_multi_method)
      bloque_parcial = definiciones_parciales[lista_de_tipos_del_multi_method]
      bloque_parcial.call_with_binding(*lista_de_argumentos_del_multi_method, instancia)
    else
      raise ArgumentError, "Ningun partial method fue encontrado con la lista de tipos <#{lista_de_tipos_del_multi_method}> referida en la key base"
    end

  end
end

class MethodCall
  attr_accessor :method_called, :tipos_parametros, :args

  def initialize(method_called, tipos, args)
    @method_called = method_called
    @tipos_parametros = tipos
    @args = args
  end

end


class Object

  :stack_llamados_a_metodos

  def stack_llamados_a_metodos
    @stack_llamados_a_metodos = @stack_llamados_a_metodos || []
  end

  def agregar_al_stack_llamados_a_metodos(nombre_metodo, tipos_parametro, args)
    stack_llamados_a_metodos.push( MethodCall.new(nombre_metodo, tipos_parametro, args) )
  end

  def partial_def (nombre,lista_parametros,&bloque)
    self.singleton_class.partial_def(nombre,lista_parametros,&bloque)
  end

  alias_method :respond_to_original?, :respond_to?

  def respond_to?(*argv)
    responde = false

    if((argv.length.eql? 1) || (argv.length.eql? 2))
      responde= self.respond_to_original?(*argv)
    else
      metodo = argv[0]
      tipos_parametros = argv[2]

      responde = self.obtener_definiciones_parciales_aplicables_a_instancia(metodo).any?  do |lista_parametros, partial_block|
        partial_block.matches_tipos(tipos_parametros)
      end
    end
    responde
  end

  def obtener_definiciones_parciales_aplicables_a_instancia(metodo)
    self.singleton_class.obtener_definiciones_parciales_aplicables_a_clase_actual(metodo)
  end

  def method_missing(metodo, *args)
    if(metodo.equal?(:base))

      instancia_cualquiera = self

      Base.new(instancia_cualquiera)

    elsif(self.is_a?(Base))

      instancia_de_base = self

      lista_de_tipos_del_multi_method = args.delete_at(0)
      lista_de_argumentos_del_multi_method = args

      instancia_de_base.ejecutar_metodo_con_base(metodo, lista_de_tipos_del_multi_method, lista_de_argumentos_del_multi_method)

    elsif(metodo.equal?(:base_posta))

      instancia_cualquiera = self
      llamado_a_metodo = @stack_llamados_a_metodos.pop

      bloque_parcial = instancia_cualquiera.singleton_class.obtener_multimethod_a_ejecutar(llamado_a_metodo.method_called, args, llamado_a_metodo.tipos_parametros)

      agregar_al_stack_llamados_a_metodos(llamado_a_metodo.method_called, bloque_parcial.lista_tipos_parametros, args)

      bloque_parcial.call_with_binding(*args, instancia_cualquiera)

      #ejecutar_base_posta_obteniendo_metodo_por_file(instancia_cualquiera, args)

    else
      super(metodo, *args)
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

    bloque_parcial.call_with_binding(*args, instancia)
  end

end
