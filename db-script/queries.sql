-- Criar usuário (table user_diets preenchido com trigger)
INSERT INTO rafalift.users (nome, email, senha, role)
VALUES ('rafa', 'rafa@email.com', '123', 0)



-- Adicionar alimento
INSERT INTO rafalift.foods (diet_id, alimento, peso, carboidratos, proteinas, fibras, gorduras, calorias)
-- diet_id (user_diets) == 1 (user: 1, segunda), calorias calculado no backend
VALUES (1, 'arroz', 100, 20, 3, 1, 9, 173)

-- Editar alimento


-- Remover alimento





-- Adicionar metas para gcd
INSERT INTO rafalift.user_gcd (user_id, carboidratos_gcd, proteinas_gcd, fibras_gcd, gorduras_gcd, gcd)
VALUES (1, 332, 91, 33, 70, 2322)