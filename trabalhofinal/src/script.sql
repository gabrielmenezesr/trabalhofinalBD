-- Criação das tabelas (DDL)
CREATE TABLE especialidade (
    id_especialidade SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descricao TEXT,
    valor_consulta DECIMAL(10,2)
);

CREATE TABLE medico (
    id_medico SERIAL PRIMARY KEY,
    id_especialidade INTEGER REFERENCES especialidade(id_especialidade),
    nome VARCHAR(100) NOT NULL,
    crm VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(15) NOT NULL,
    dias_atendimento VARCHAR(100),
    horario_inicio TIME,
    horario_fim TIME
);

CREATE TABLE paciente (
    id_paciente SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    data_nascimento DATE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(15) NOT NULL,
    endereco VARCHAR(200),
    plano_saude VARCHAR(50),
    grupo_sanguineo VARCHAR(3),
    alergias TEXT
);

CREATE TABLE agendamento (
    id_agendamento SERIAL PRIMARY KEY,
    id_paciente INTEGER REFERENCES paciente(id_paciente),
    id_medico INTEGER REFERENCES medico(id_medico),
    data_hora TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Agendada', 'Confirmada', 'Realizada', 'Cancelada')),
    forma_pagamento VARCHAR(50),
    valor DECIMAL(10,2),
    UNIQUE (id_medico, data_hora)
);

CREATE TABLE atendimento (
    id_atendimento SERIAL PRIMARY KEY,
    id_agendamento INTEGER REFERENCES agendamento(id_agendamento),
    data_inicio TIMESTAMP NOT NULL,
    data_fim TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Em Andamento', 'Concluído', 'Cancelado')),
    observacoes TEXT
);

CREATE TABLE prontuario (
    id_prontuario SERIAL PRIMARY KEY,
    id_paciente INTEGER REFERENCES paciente(id_paciente),
    id_atendimento INTEGER REFERENCES atendimento(id_atendimento),
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    queixa_principal TEXT NOT NULL,
    diagnostico TEXT,
    prescricao TEXT,
    observacoes TEXT
);

CREATE TABLE exame (
    id_exame SERIAL PRIMARY KEY,
    id_prontuario INTEGER REFERENCES prontuario(id_prontuario),
    tipo_exame VARCHAR(100) NOT NULL,
    data_solicitacao DATE NOT NULL,
    data_realizacao DATE,
    resultado TEXT,
    anexo BYTEA
);

CREATE TABLE medicamento (
    id_medicamento SERIAL PRIMARY KEY,
    id_prontuario INTEGER REFERENCES prontuario(id_prontuario),
    nome VARCHAR(100) NOT NULL,
    dosagem VARCHAR(50) NOT NULL,
    frequencia VARCHAR(50) NOT NULL,
    duracao VARCHAR(50),
    observacoes TEXT
);

-- Inserção de dados de exemplo (DML)
INSERT INTO especialidade (nome, valor_consulta) VALUES
('Cardiologia', 250.00),
('Dermatologia', 200.00),
('Ortopedia', 200.00),
('Clínico Geral', 150.00);


INSERT INTO medico (id_especialidade, nome, crm, telefone, email) VALUES
(1, 'Dr. Bruce Monteiro', '45678-MG', '(31) 98765-4321', 'bruce.monteiro@clinica.com.br'),
(2, 'Dr. Gabriel Menezes', '56789-MG', '(31) 98765-4322', 'gabriel.menezes@clinica.com.br'),
(3, 'Dr. Bruno Lott', '67890-MG', '(31) 98765-4323', 'bruno.lott@clinica.com.br'),
(4, 'Dr. Iago Mendes', '78901-MG', '(31) 98765-4324', 'iago.mendes@clinica.com.br');

-- Views para relatórios
CREATE VIEW relatorio_agendamentos_medico AS
SELECT
    m.nome AS medico,
    e.nome AS especialidade,
    COUNT(a.id_agendamento) AS total_agendamentos,
    COUNT(CASE WHEN a.status = 'Realizada' THEN 1 END) AS consultas_realizadas
FROM medico m
JOIN especialidade e ON m.id_especialidade = e.id_especialidade
LEFT JOIN agendamento a ON m.id_medico = a.id_medico
WHERE a.data_hora BETWEEN :data_inicio AND :data_fim
GROUP BY m.id_medico, m.nome, e.nome;

CREATE VIEW relatorio_prontuarios_paciente AS
SELECT
    p.nome AS paciente,
    p.cpf,
    m.nome AS medico,
    e.nome AS especialidade,
    a.data_hora AS data_consulta,
    pr.queixa_principal,
    pr.diagnostico,
    pr.prescricao
FROM prontuario pr
JOIN paciente p ON pr.id_paciente = p.id_paciente
JOIN atendimento at ON pr.id_atendimento = at.id_atendimento
JOIN agendamento a ON at.id_agendamento = a.id_agendamento
JOIN medico m ON a.id_medico = m.id_medico
JOIN especialidade e ON m.id_especialidade = e.id_especialidade
ORDER BY a.data_hora DESC;