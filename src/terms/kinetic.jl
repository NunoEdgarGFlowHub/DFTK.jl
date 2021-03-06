"""
Kinetic energy: 1/2 sum_n f_n ∫ |∇ψn|^2.
"""
struct Kinetic end
(K::Kinetic)(basis) = TermKinetic(basis)

struct TermKinetic <: Term
    basis::PlaneWaveBasis
    kinetic_energies::Vector{Vector} # kinetic energy 1/2|G+k|^2 for every kpoint
end
function TermKinetic(basis::PlaneWaveBasis)
    kinetic_energies = [[sum(abs2, basis.model.recip_lattice * (G + kpt.coordinate)) / 2
                         for G in G_vectors(kpt)]
                        for kpt in basis.kpoints]
    TermKinetic(basis, kinetic_energies)
end

function ene_ops(term::TermKinetic, ψ, occ; kwargs...)
    basis = term.basis
    T = eltype(basis)

    ops = [FourierMultiplication(basis, kpoint, term.kinetic_energies[ik])
           for (ik, kpoint) in enumerate(basis.kpoints)]
    ψ === nothing && return (E=T(Inf), ops=ops)

    E = zero(T)
    for (ik, k) in enumerate(basis.kpoints)
        for iband = 1:size(ψ[1], 2)
            ψnk = @views ψ[ik][:, iband]
            E += (basis.kweights[ik] * occ[ik][iband]
                  * real(dot(ψnk, term.kinetic_energies[ik] .* ψnk)))
        end
    end

    (E=E, ops=ops)
end
